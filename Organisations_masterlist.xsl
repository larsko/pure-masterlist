<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
	xmlns:commons="v3.commons.pure.atira.dk" 
	xmlns="v1.organisation-sync.pure.atira.dk"
	xmlns:python="python" exclude-result-prefixes="python">

<xsl:output method="xml" indent="yes" />


<!-- Passing this from Python -->
<xsl:param name="language"/>
<xsl:param name="country"/>

<!-- Locale - not we could grab this from Python, but this is to make it explicit
<xsl:variable name="language" select="'en'" />
<xsl:variable name="country" select="'US'" /> -->

<xsl:template match="root">
	<organisations>
		<xsl:comment>This data was auto-generated using a tool.</xsl:comment>
		
		<xsl:apply-templates select="item" />

	</organisations>
</xsl:template>

<!-- The organisation -->
<xsl:template match="item">
	
	<organisation managedInPure="false">
		<organisationId><xsl:value-of select="OrganisationID" /></organisationId>
	        <type><xsl:value-of select="Type"/></type>
	        <name>
	             <xsl:call-template name="text">
						<xsl:with-param name="val" select="Name_en" />
				</xsl:call-template>
	       </name>
	       <startDate><xsl:value-of select="StartDate" /></startDate>
	       <xsl:if test="EndDate/text()"><endDate><xsl:value-of select="EndDate" /></endDate></xsl:if>
	       <visibility><xsl:value-of select="Visibility" /></visibility>

	       <xsl:apply-templates select="OrganisationalHierarchy" />

	</organisation>

</xsl:template>

<!-- For each parent ID - note there can be multiple! -->
<xsl:template match="OrganisationalHierarchy">
	<xsl:for-each select="item">
		<parentOrganisationId><xsl:value-of select="ParentOrganisationID" /></parentOrganisationId>
	</xsl:for-each>
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