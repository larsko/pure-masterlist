<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
	xmlns:commons="v3.commons.pure.atira.dk" 
	xmlns="v1.unified-person-sync.pure.atira.dk"
	xmlns:python="python" exclude-result-prefixes="python">

<xsl:output method="xml" indent="yes" />

<!-- Passing this from Python -->
<xsl:param name="language"/>
<xsl:param name="country"/>

<!-- Locale - not we could grab this from Python, but this is to make it explicit 
<xsl:variable name="language" select="'en'" />
<xsl:variable name="country" select="'US'" />-->

<xsl:template match="root">
	<persons>
		<xsl:comment>This data was auto-generated using a tool.</xsl:comment>
		<xsl:apply-templates select="item" />

	</persons>
</xsl:template>

<xsl:template match="item">

	<person id="{PersonID}" managedInPure="false">

		<!-- Name -->
		<name>
			<commons:firstname><xsl:value-of select="Firstname" /></commons:firstname>
			<commons:lastname><xsl:value-of select="Lastname" /></commons:lastname>
		</name>

		<!-- Name variants -->
		<xsl:call-template name="create_names" select="." />

		<!-- Titles -->
		<xsl:if test="Title/node() | PostNominals/node()">
			<titles>
				<xsl:apply-templates select="Title | PostNominals" />
			</titles>
		</xsl:if>

		<!-- Gender -->
		<gender><xsl:value-of select="Gender" /></gender>

		<!-- Nationality -->
		<xsl:apply-templates select="Nationality" />
		
		<expert>true</expert>
		
		<!-- Photo -->
		<xsl:if test="ProfilePhoto/node()">
			<xsl:apply-templates select="ProfilePhoto" />
		</xsl:if>
		
		<!-- Relations -->
		<xsl:apply-templates select="Stafforganisationrelations" />

		<!-- Profile Info -->
		<xsl:apply-templates select="PersonProfileInformation" />

		<!-- User -->
		<xsl:apply-templates select="user" />

		<!-- IDs -->
		<xsl:apply-templates select="ids" />

		<!-- ORCID -->
		<xsl:apply-templates select="ORCID"/>

		<!-- Visibility -->
		<visibility><xsl:value-of select="Visibility" /></visibility>

		<!-- Profiled -->
		<xsl:apply-templates select="Profiled" />
	</person>

</xsl:template>

<xsl:template name="create_names">
	<xsl:variable name="name_translated" select="Firstname_translated | Lastname_translated" />
	<xsl:variable name="name_knownas" select="FirstNameKnownAs | LastNameKnownAs" />
	<xsl:variable name="name_sorting" select="FirstNameSorting | LastNameSorting" />
	<xsl:variable name="name_former" select="FormerLastName" />

	<!-- variants are separate elements in the XML, so we need combine nodesets and check. -->
	<xsl:if test="$name_translated | $name_knownas | $name_sorting | $name_former">
		<names>

			<!-- translated -->
			<xsl:call-template name="name_variant">
				<xsl:with-param name="testNode" select="$name_translated" />
				<xsl:with-param name="firstname" select="Firstname_translated" />
				<xsl:with-param name="lastname" select="Lastname_translated" />
				<xsl:with-param name="type" select="'translated'" />
			</xsl:call-template>

			<!-- knownas -->
			<xsl:call-template name="name_variant">
				<xsl:with-param name="testNode" select="$name_knownas" />
				<xsl:with-param name="firstname" select="FirstNameKnownAs" />
				<xsl:with-param name="lastname" select="LastNameKnownAs" />
				<xsl:with-param name="type" select="'knownas'" />
			</xsl:call-template>

			<!-- sort -->
			<xsl:call-template name="name_variant">
				<xsl:with-param name="testNode" select="$name_sorting" />
				<xsl:with-param name="firstname" select="FirstNameSorting" />
				<xsl:with-param name="lastname" select="LastNameSorting" />
				<xsl:with-param name="type" select="'sort'" />
			</xsl:call-template>

			<!-- former -->
			<xsl:call-template name="name_variant">
				<xsl:with-param name="testNode" select="$name_former" />
				<xsl:with-param name="lastname" select="FormerLastName" />
				<xsl:with-param name="type" select="'former'" />
			</xsl:call-template>

		</names>
	</xsl:if>	
</xsl:template>

<xsl:template match="PersonProfileInformation">
	<xsl:for-each select="item">
        <profileInformation>
	        <personCustomField id="{id}">
	            <typeClassification><xsl:value-of select="ProfileInformationType" /></typeClassification>
	            <value>
	                <xsl:call-template name="text">
						<xsl:with-param name="val" select="ProfileInformationText" />
					</xsl:call-template>
	            </value>
	        </personCustomField>
    	</profileInformation>		
	</xsl:for-each>
</xsl:template>

<xsl:template match="PersonExternalPositions">
	<externalPositions>
		<xsl:for-each select="item">
			<externalPosition id="FIX-THIS">
				<xsl:if test="StartDate/node()">
	                <startDate>
	                    <commons:year><xsl:value-of select="start_year" /></commons:year>
	                    <commons:month><xsl:value-of select="start_month" /></commons:month>
	                    <commons:day><xsl:value-of select="start_day" /></commons:day>
	                </startDate>
				</xsl:if>
				<xsl:if test="EndDate/node()">
	                <endDate>
	                    <commons:year><xsl:value-of select="end_year" /></commons:year>
	                    <commons:month><xsl:value-of select="end_month" /></commons:month>
	                    <commons:day><xsl:value-of select="end_day" /></commons:day>
	                </endDate>
				</xsl:if>                
	            <appointmentString><xsl:value-of select="Appointment" /></appointmentString>
	            <externalOrganisationAssociation>
	                <externalOrganisation>
	                	<name><xsl:value-of select="Organisation" /></name>
	                </externalOrganisation>
	            </externalOrganisationAssociation>
	        </externalPosition>
		</xsl:for-each>
	</externalPositions>
</xsl:template>

<xsl:template match="Nationality">
	<nationality><xsl:value-of select="." /></nationality>
</xsl:template>

<xsl:template match="ORCID">
	<orcId><xsl:value-of select="." /></orcId>
</xsl:template>

<xsl:template match="Profiled">
	<profiled><xsl:value-of select="." /></profiled>
</xsl:template>

<!-- the person org associations -->
<!-- TODO: can expand on the different additional content here... -->
<xsl:template match="Stafforganisationrelations">
	<organisationAssociations>
		<xsl:for-each select="item">
			<xsl:element name="Stafforganisationrelation">
				<xsl:attribute name="id"><xsl:value-of select="id" /></xsl:attribute>

				<xsl:if test="phone/node() | mobile/node() | fax/node()">
					<phoneNumbers>
						<xsl:apply-templates select="phone | mobile | fax"/>
					</phoneNumbers>	
				</xsl:if>
				
				<xsl:apply-templates select="Email"/>
				<xsl:apply-templates select="WebsiteURL"/>
				<employmentType><xsl:value-of select="EmployedAs" /></employmentType>
				<xsl:if test="Primary='yes'">
					<primaryAssociation><xsl:value-of select="Primary" /></primaryAssociation>
				</xsl:if>
                <organisation>
                    <commons:non_explicit_id><xsl:value-of select="OrganisationID"/></commons:non_explicit_id>
                </organisation>
                <period>
                    <commons:startDate><xsl:value-of select="StartDate" /></commons:startDate>
                    <xsl:if test="EndDate != ''">
                    	<commons:endDate>
                    		<xsl:value-of select="EndDate" />
                    	</commons:endDate>
                    </xsl:if>
                </period>

                <xsl:choose>
                	<xsl:when test="StaffType = 'academic'">
                		<staffType><xsl:value-of select="StaffType" /></staffType>
		                <jobDescription>
		                    <xsl:call-template name="text">
								<xsl:with-param name="val" select="JobDescription" />
							</xsl:call-template>
		                </jobDescription>
		                <xsl:if test="FTE/node()">
		                	<fte><xsl:value-of select="FTE" /></fte>
		                </xsl:if>
                	</xsl:when>
                </xsl:choose>

               </xsl:element>
		</xsl:for-each>
	</organisationAssociations>
</xsl:template>

<xsl:template match="phone | mobile | fax">
	<xsl:if test="./node()">
	    <commons:classifiedPhoneNumber id="{ancestor::item/id}_{name()}">
	        <commons:classification><xsl:value-of select="name()" /></commons:classification>
	        <commons:value><xsl:value-of select="." /></commons:value>
	    </commons:classifiedPhoneNumber>
    </xsl:if>
</xsl:template>

<!-- note: only supports 1 email as in masterlist -->
<xsl:template match="Email/node()">
    <emails>
        <commons:classifiedEmail id="{ancestor::item/id}_email">
            <commons:classification>email</commons:classification>
            <commons:value><xsl:value-of select="." /></commons:value>
        </commons:classifiedEmail>
    </emails>	
</xsl:template>

<!-- note: only supports 1 website currently -->
<xsl:template match="WebsiteURL">

    <webAddresses>
        <commons:classifiedWebAddress id="{ancestor::item/id}_website">
            <commons:classification>web</commons:classification>
            <commons:value>
                 <xsl:call-template name="text">
						<xsl:with-param name="val" select="." />
					</xsl:call-template>
            </commons:value>
        </commons:classifiedWebAddress>
    </webAddresses>

</xsl:template>

<!-- person name variant -->
<xsl:template name="name_variant">
	<xsl:param name="testNode" />
	<xsl:param name="firstname" />
	<xsl:param name="lastname" />
	<xsl:param name="type" />

	<xsl:if test="$testNode/node()">
		<classifiedName id="{ancestor::*//PersonID}_name_{$type}">
			<name>
				<commons:firstname><xsl:value-of select="$firstname" /></commons:firstname>
	            <commons:lastname><xsl:value-of select="$lastname" /></commons:lastname>
			</name>
			<typeClassification><xsl:value-of select="$type" /></typeClassification>
		</classifiedName>
	</xsl:if>

</xsl:template>

<!-- person titles - ensure that typeClassification exists in Pure -->
<xsl:template match="Title | PostNominals">
	<xsl:if test="./node()">
		<title id="{ancestor::item/PersonID}_{name()}">
			<typeClassification>
				<xsl:choose>
					<xsl:when test="name()='PostNominals'">postnominal</xsl:when>
					<xsl:otherwise>designation</xsl:otherwise>
				</xsl:choose>
			</typeClassification>
			<value>
				<xsl:call-template name="text">
					<xsl:with-param name="val" select="." />
				</xsl:call-template>
			</value>
		</title>	
	</xsl:if>
</xsl:template>

<xsl:template match="ids">
	
	<personIds>
		<xsl:for-each select="item">
			<commons:id type="{type}" id="{id}"><xsl:value-of select="id" /></commons:id>
		</xsl:for-each>
	</personIds>

</xsl:template>

<xsl:template match="user">
	<user id="{userName}">
		<userName><xsl:value-of select="userName" /></userName>
		<email><xsl:value-of select="email" /></email>
	</user>
</xsl:template>

<xsl:template match="ProfilePhoto">
	<xsl:if test="./node()">
	<photos>
		<personPhoto id="{ancestor::item/PersonID}_photo">
			<classification>portrait</classification>
			<data>
				<xsl:choose>
					<xsl:when test="ancestor::item/IsPhotoUrl/text()='True'">
						<http>
							<url><xsl:value-of select="." /></url>
							<fileName><xsl:value-of select="." />.jpg</fileName>
						</http>
					</xsl:when>
					<xsl:otherwise>
						<file>
							<path><xsl:value-of select="." /></path>
							<fileName><xsl:value-of select="." />.jpg</fileName>
						</file>
					</xsl:otherwise>
				</xsl:choose>
			</data>
		</personPhoto>
	</photos>
	</xsl:if>
</xsl:template>

<!-- Creates a localized string based on the language and country (if specified) -->
<xsl:template name="text" >
	<xsl:param name="val" />
	<xsl:param name="escape" select="'no'" />

	<commons:text lang="{$language}">
		<xsl:if test="$country">
			<xsl:attribute name="country"><xsl:value-of select="$country" /></xsl:attribute>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="$escape != ''">
				<xsl:value-of disable-output-escaping="yes" select="$val" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$val" />
			</xsl:otherwise>
		</xsl:choose>		
	</commons:text>
</xsl:template>

</xsl:transform>