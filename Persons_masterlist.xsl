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

		<name>
			<commons:firstname><xsl:value-of select="Firstname" /></commons:firstname>
			<commons:lastname><xsl:value-of select="Lastname" /></commons:lastname>
		</name>

		<xsl:apply-templates select="names" />

		<xsl:call-template name="titles" />

		<gender><xsl:value-of select="Gender" /></gender>

		<xsl:apply-templates select="nationality" />
		
		<expert>true</expert>
		
		<xsl:apply-templates select="ProfilePhoto" />
		
		<xsl:apply-templates select="phd_research_projects"/>
		
		<xsl:apply-templates select="Stafforganisationrelations" />
		
		<xsl:apply-templates select="education" />
		
		<xsl:apply-templates select="external_positions" />
		 
		<xsl:apply-templates select="profile_information" />
<!--
		<professionalQualifications></professionalQualifications>

		<keywords></keywords> -->

		<xsl:apply-templates select="links" />

		<xsl:apply-templates select="user" />

		<xsl:apply-templates select="ids" />

		<xsl:apply-templates select="ORCID"/>

		<visibility><xsl:value-of select="Visibility" /></visibility>

		<xsl:apply-templates select="Profiled" />
	</person>

</xsl:template>

<xsl:template match="profile_information">
        <profileInformation>
        <personCustomField id="{id}">
            <typeClassification>researchinterests</typeClassification>
            <value>
                <xsl:call-template name="text">
					<xsl:with-param name="val" select="text" />
				</xsl:call-template>
            </value>
        </personCustomField>
    </profileInformation>
</xsl:template>

<xsl:template match="external_positions">
	<externalPositions>

	<xsl:for-each select="*">
	
		<externalPosition id="{id}">
                <startDate>
                    <commons:year><xsl:value-of select="start_date/y" /></commons:year>
                    <commons:month><xsl:value-of select="start_date/m" /></commons:month>
                    <commons:day><xsl:value-of select="start_date/d" /></commons:day>
                </startDate>
                <endDate>
                    <commons:year><xsl:value-of select="end_date/y" /></commons:year>
                    <commons:month><xsl:value-of select="end_date/m" /></commons:month>
                    <commons:day><xsl:value-of select="end_date/d" /></commons:day>
                </endDate>
                <!--<appointment><xsl:value-of select="appointment" /></appointment>-->
                <appointmentString><xsl:value-of select="appointment" /></appointmentString>
                <externalOrganisationAssociation>
                    <externalOrganisation>
                    	<name><xsl:value-of select="organisation" /></name>
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

				<xsl:if test="phone | mobile | fax">
					<phoneNumbers>
						<xsl:apply-templates select="phone | mobile | fax"/>
					</phoneNumbers>	
				</xsl:if>
				
				<xsl:apply-templates select="Email"/>
				<xsl:apply-templates select="websites"/>
				<!--<employmentType><xsl:value-of select="employment" /></employmentType>-->
				<xsl:if test="Primary='yes'">
					<primaryAssociation><xsl:value-of select="Primary" /></primaryAssociation>
				</xsl:if>
                <organisation>
                    <commons:non_explicit_id><xsl:value-of select="organisation_id"/></commons:non_explicit_id>
                </organisation>
                <period>
                    <commons:startDate><xsl:value-of select="start" /></commons:startDate>
                    <xsl:if test="end != ''">
                    	<commons:endDate>
                    		<xsl:value-of select="end" />
                    	</commons:endDate>
                    </xsl:if>
                </period>

                <xsl:choose>
                	<xsl:when test="association = 'staffOrganisationAssociation'">
                		<staffType><xsl:value-of select="type" /></staffType>
		                <!--<contractType>fixedterm</contractType>-->
		                <!--<jobTitle>juniorprofessor</jobTitle>-->
		                <jobDescription>
		                    <xsl:call-template name="text">
								<xsl:with-param name="val" select="job_description" />
							</xsl:call-template>
		                </jobDescription>
                	</xsl:when>
                	<xsl:otherwise></xsl:otherwise>
                </xsl:choose>

               </xsl:element>
		</xsl:for-each>
	</organisationAssociations>
</xsl:template>

<!-- note: only supports 1 phone number currently -->
<xsl:template match="phone | mobile | fax">

    <commons:classifiedPhoneNumber id="FIX-THIS">
        <commons:classification><xsl:value-of select="name()" /></commons:classification>
        <commons:value><xsl:value-of select="." /></commons:value>
    </commons:classifiedPhoneNumber>

</xsl:template>

<!-- note: only supports 1 email as in masterlist -->
<xsl:template match="Email">
    <emails>
        <commons:classifiedEmail id="FIX-THIS">
            <commons:classification>email</commons:classification>
            <commons:value><xsl:value-of select="." /></commons:value>
        </commons:classifiedEmail>
    </emails>	
</xsl:template>

<!-- note: only supports 1 website currently -->
<xsl:template match="websites">

    <webAddresses>
        <commons:classifiedWebAddress id="{id}">
            <commons:classification>web</commons:classification>
            <commons:value>
                 <xsl:call-template name="text">
						<xsl:with-param name="val" select="value" />
					</xsl:call-template>
            </commons:value>
        </commons:classifiedWebAddress>
    </webAddresses>

</xsl:template>

<!-- person name variants -->
<xsl:template match="names">
	
	<names>
		<xsl:for-each select="*">
			<classifiedName id="{name()}">
				<name>
					<commons:firstname><xsl:value-of select="firstname" /></commons:firstname>
	                <commons:lastname><xsl:value-of select="lastname" /></commons:lastname>
				</name>
				<typeClassification><xsl:value-of select="name()" /></typeClassification>
			</classifiedName>
		</xsl:for-each>
	</names>

</xsl:template>

<!-- person willing to take phd students -->
<xsl:template match="willingness_to_phd">
	<willingnessToPhd><xsl:value-of select="." /></willingnessToPhd>
</xsl:template>

<!-- person phd projects - think this is legacy -->
<xsl:template match="phd_research_projects">
	<phdResearchProjects><xsl:value-of select="phdResearchProjects" /></phdResearchProjects>
</xsl:template>

<!-- person titles - ensure that typeClassification exists in Pure -->
<xsl:template name="titles">
	<titles>
		<xsl:for-each select="Title | Postnominals">
			<title id="{name()}">
				<typeClassification><xsl:value-of select="name()" /></typeClassification>
				<value>
					<xsl:call-template name="text">
						<xsl:with-param name="val" select="text()" />
					</xsl:call-template>
				</value>
			</title>	
		</xsl:for-each>
	</titles>
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
	<photos>

		<personPhoto id="{id}">
			<classification><xsl:value-of select="name()" /></classification>
			<data>
				<http>
					<url><xsl:value-of select="." /></url>
					<fileName><xsl:value-of select="." />.jpg</fileName>
				</http>
			</data>
		</personPhoto>

	</photos>
</xsl:template>

<!-- Creates a localized string based on the language and country -->
<xsl:template name="text" >
	<xsl:param name="val" />
	<xsl:param name="escape" select="'no'" />

	<commons:text lang="{$language}" country="{$country}">
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