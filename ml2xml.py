import pandas as pd
import json
import click
import dicttoxml
import lxml.etree as ET
from xml.dom import minidom
from pathlib import Path
from validator_collection import checkers

# We don't need lists and classifications (right now)
excluded_sheets = ['Lists', 'Classifications']

# Set targets: Orgs and Persons
master_data = [
	('Organisations', 'OrganisationID', 'Stafforganisationrelations'),
	('Persons','PersonID', '')
	]

class_data = []

# the client ID columns
client_ids = ["ClientID_{0}".format(i) for i in range(1,4)]

@click.argument('masterlist')
@click.option('--clean/--no-clean', default=False, help='Delete all existing XML files in current directory.')
@click.option('--language', default='en-GB', help='String locale. Default is "en-GB" Usage: e.g. "es" and "da-DK". ')
@click.option('--classifications/--no-classifications', default=False, help='Outputs the classification schemes found in the masterlist.')
@click.command()
def convert_masterlist(masterlist, clean, language, classifications):
	
	click.echo(click.style("Converting masterlist to XML...", bold = True) )

	if clean:
		clean_files()

	# Load the masterlist
	ml = pd.ExcelFile(masterlist)

	# First step, only process content sheets - save classifications for later.
	content_types = (c for c in ml.sheet_names if c not in excluded_sheets)
	
	# Load each worksheet
	content_data = load_data_sheets(ml, content_types)
	
	# Load classifications
	global class_data
	class_data = load_classification_sheets(ml)

	for master_target in master_data:

		name = master_target[0]

		file = Path(name+'.xml')
		xml_dom = ''
		if file.is_file():
			xml_dom = ET.parse(name+'.xml').getroot()
		else:
			# Create nested data structure
			data = process_relations(master_target, content_data)
			# Convert it to XML
			xml_dom = convert_to_xml(data, name)
		# Apply XSLT
		transform_xml(xml_dom, name, class_data, language)

	if classifications:
		print_classifications()

	click.echo(click.style("All done!", bold = True, fg='green'))

def clean_files():
	for p in Path(".").glob("*.xml"):
		p.unlink()

def print_classifications():
	click.echo(click.style("Classifications found in the masterlist:", fg='blue'))
	for classification in class_data:
		click.echo(classification['scheme']+':')
		for uri in classification['values']:
			click.echo('\t'+uri) 	

def load_classification_sheets(masterlist):
	df = pd.read_excel(masterlist, 'Classifications', index=False)

	# sheet contains extra space - we need to get rid of this.
	df = df.dropna(axis=1, how='all').dropna(how='all')
	df = df.set_index('Classifications')
	df = df[df.index.notnull()]

	# some slicing and dicing needed to get the URI values we want...
	classifications = []
	for i in range(0, 20, 5):
		df_sub = df[i:i + 5].copy()
		df_sub = df_sub.dropna(axis=1,how='all')
		df_sub.index.name = (df_sub.iloc[1,0])
		df_sub.drop(df_sub.index[1:2],inplace=True)
		uri = df_sub.loc['uri'].dropna().to_list()
		classifications.append(
			{
			'scheme': df_sub.index.name,
			'name': df_sub.index.name.split('/')[-1],
			'values':uri
			}
		)

	return classifications

def load_data_sheets(masterlist, sheets, remove_null_vales = True):
	result = {}
	for sheet in sheets:
		df = fix_dataframe(pd.read_excel(masterlist, sheet, parse_dates=True), sheet)
		js = json.loads(df.to_json(orient = 'records'))

		# Remove empty values to reduce size. Disable for debugging XML.
		if remove_null_vales:
			coll = []
			for item in js:
				coll.append({ k:v for k,v in item.items() if v != None})

			result[sheet] = coll
		else:
			result[sheet] = js

	return result

def convert_to_xml(data, type):
	root = ET.Element('root')

	with click.progressbar(data, label = 'Coverting {0} to XML...'.format(type)) as bar:
		for item in bar:
			xml_dict = dicttoxml.dicttoxml(item, custom_root = 'item')
			xml_str = minidom.parseString(xml_dict).toprettyxml(indent="   ") 
			root.append(ET.fromstring(xml_str))	

	return root

# gets corresponding classification scheme using its 'local' name.
def get_classifications(name):
	# Note: class_data is a global variable
	for c in class_data:
		if c['name'] == name:
			return c

# XSLT function
def get_client_id_uri(context, name):
	scheme = get_classifications('personsources')
	ids = dict(zip(client_ids, scheme['values']))

	if not name in ids:
		return 'MISSING_CLASSIFICATION_URI'

	return ids[name]

def transform_xml(xml, name, classifications, lang='en-GB'):

	ET.ElementTree(xml).write(name+'.xml')

	language = lang
	country = ''
	if '-' in lang:
		language, country = tuple(lang.split("-"))

	# Add custom functions to XSLT context
	ns = ET.FunctionNamespace("python")
	ns['get_client_id_uri'] = get_client_id_uri

	transform = ET.XSLT(ET.parse(name+'_masterlist.xsl'))
	trans_xml = transform(xml,		
			language = ET.XSLT.strparam(language), 
			country = ET.XSLT.strparam(country)
		)
	trans_xml.write(name+'_converted.xml', pretty_print = True, xml_declaration = True, encoding = "utf-8", standalone = True)

# for custom processing of certain sheets
def fix_dataframe(df, sheet):
	
	# drop the documentation row in the masterlist
	df = df.drop(df.index[0])

	# we need to provide parents for each child, so swap the order
	if sheet == 'OrganisationalHierarchy':
		
		df.columns = ['ParentOrganisationID','OrganisationID']
	
	elif sheet == 'Stafforganisationrelations':
		
		df["id"] = "autoid:" + df["PersonID"] + "-" + df["OrganisationID"] + "-" + df["EmployedAs"] + "-" + df["StartDate"].astype(str) 
		
		#rename phone,fax,mobile
		df.rename(inplace=True, index=str, columns = { "DirectPhoneNr": "phone", "MobilePhoneNr":"mobile", "FaxNr" : "fax" })
	
	elif sheet == "Persons":
		
		df["Gender"] = df["Gender"].replace("","unknown")

		# check if photo and if file or URL.
		df['IsPhotoUrl'] = df["ProfilePhoto"].astype(str).map(checkers.is_url)

	elif sheet == "PersonExternalPositions":
		
		# break out dates into components
		starts = pd.to_datetime(df["StartDate"]).dt
		ends = pd.to_datetime(df["EndDate"]).dt

		df = df.assign(
			start_year=starts.year.fillna(0).astype(int), 
			start_month=starts.month.fillna(0).astype(int), 
			start_day=starts.day.fillna(0).astype(int)
		)
		df = df.assign(
			end_year=starts.year.fillna(0).astype(int), 
			end_month=starts.month.fillna(0).astype(int), 
			end_day=starts.day.fillna(0).astype(int)
		)

	return df

# Process relations for a target content type (orgs or persons)
def process_relations(target_sheet, json_sheets):

	target, key, ignore = target_sheet

	for data_item in json_sheets[target]:
		source_id = data_item[key]

		# check all sheets for the corresponding source ID and link up
		for sheet in json_sheets:
			if (sheet != target and sheet != ignore):

				for item in json_sheets[sheet]:
					if (key in item):
						target_id = item[key]
						
						# Check if target has this relation
						if (source_id == target_id):

							if (not sheet in data_item):
								data_item[sheet] = []

							data_item[sheet].append(item)

	return json_sheets[target]

if __name__ == '__main__':
    convert_masterlist()