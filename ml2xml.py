import pandas as pd
import json
import click
import dicttoxml
import lxml.etree as ET
from xml.dom import minidom
from pathlib import Path

# We don't need lists and classifications (right now)
excluded_sheets = ['Lists', 'Classifications']

# Set targets: Orgs and Persons
master_data = [
	('Organisations', 'OrganisationID', 'Stafforganisationrelations'),
	('Persons','PersonID', '')
	]

@click.argument('masterlist')
@click.option('--clean/--no-clean', default=False, help='Delete XML files.')
@click.command()
def convert_masterlist(masterlist, clean):
	
	click.echo(click.style("Converting masterlist to XML...", bold = True) )

	if clean:
		clean_files()

	# Load the masterlist
	master_list = pd.ExcelFile(masterlist)

	# First step, only process content sheets - save classifications for later.
	content_types = (sheet for sheet in master_list.sheet_names if sheet not in excluded_sheets)

	content_data = load_data_sheets(master_list, content_types, False)

	#class_data = load_classification_sheets(master_list)

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
		transform_xml(xml_dom,name)

	click.echo(click.style("All done!", bold = True, fg='green'))

def clean_files():
	for p in Path(".").glob("*.xml"):
		p.unlink()

def transform_xml(xml, name, lang='en-US'):

	ET.ElementTree(xml).write(name+'.xml')

	transform = ET.XSLT(ET.parse(name+'_masterlist.xsl'))
	trans_xml = transform(xml,		
			language = ET.XSLT.strparam(lang.split("-")[0].lower()), 
			country = ET.XSLT.strparam(lang.split("-")[1].upper()))
	trans_xml.write(name+'_converted.xml', pretty_print = True, xml_declaration = True, encoding = "utf-8", standalone = True)

def load_classification_sheets(masterlist):
	df = pd.read_excel(masterlist, 'Classifications')
	# sheet contains extra space - we need to get rid of this.
	df = df.dropna(axis=1,how='all').dropna(how='all')
	#df = df[df['Classifications'].isin(['uri','Scheme'])]
	#df.rename(columns = {'Unnamed: 1': 'dummy'}, inplace = True)
	#print(pd.melt(df, id_vars=['dummy'], value_vars =['Classifications']).dropna())
	df = df.set_index('Classifications')
	#print(df.iloc[ (df.loc['Classification for:']).values, 5])
	#print(pd.melt(df).dropna())
	return df

def load_data_sheets(masterlist, sheets, remove_null_vales = True):
	result = {}
	for sheet in sheets:
		df = fix_dataframe(pd.read_excel(masterlist, sheet), sheet)
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

# for custom processing of certain sheets
def fix_dataframe(df, sheet):
	
	# drop the documentation row
	df = df.drop(df.index[0])

	# we need to provide parents for each child, so swap the order
	if sheet == 'OrganisationalHierarchy':
		df.columns = ['ParentOrganisationID','OrganisationID']
	elif sheet == 'Stafforganisationrelations':
		df["id"] = "autoid:" + df["PersonID"] + "-" + df["OrganisationID"] + "-" + df["EmployedAs"] + "-" + df["StartDate"] 
		#rename phone,fax,mobile
		df.rename(inplace=True, index=str, columns ={ "DirectPhoneNr": "phone", "MobilePhoneNr":"mobile", "FaxNr" : "fax" })
	elif sheet == "Persons":
		df["Gender"] = df["Gender"].replace("","unknown")
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