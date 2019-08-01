<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
	xmlns:commons="v3.commons.pure.atira.dk" 
	xmlns="v1.organisation-sync.pure.atira.dk"
	xmlns:python="python" exclude-result-prefixes="python">

<xsl:output method="xml" indent="yes" />


<!-- Passing this from Python -->
<xsl:param name="language"/>
<xsl:param name="country"/>

<!-- Secondary language -->
<xsl:param name="language2"/>
<xsl:param name="country2"/>

<xsl:param name="translated"/>

<!-- / End Python -->

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
		<xsl:if test="Name_translated and $translated = 'True'">
			<name>
				 <xsl:call-template name="text">
						<xsl:with-param name="val" select="Name_translated" />
						<xsl:with-param name="translated" select="$translated" />
				</xsl:call-template>
			</name>
		</xsl:if>
	    
	    <!-- dates -->
		<startDate><xsl:value-of select="StartDate" /></startDate>
		<xsl:if test="EndDate/text()"><endDate><xsl:value-of select="EndDate" /></endDate></xsl:if>

		<xsl:call-template name="ProfileInfo" />

		<xsl:if test="PhoneNumber/node() | FaxNumber/node()">
			<xsl:call-template name="Numbers" />
		</xsl:if>

		<xsl:apply-templates select="Email" />

		<xsl:call-template name="Address" />

		<visibility>
			<xsl:choose>
				<xsl:when test="Visibility/node()"><xsl:value-of select="Visibility" /></xsl:when>
				<xsl:otherwise>public</xsl:otherwise>
			</xsl:choose>
		</visibility>

		<xsl:apply-templates select="OrganisationalHierarchy" />

	</organisation>

</xsl:template>

<xsl:template name="Numbers">
	<phoneNumbers>
		<xsl:if test="PhoneNumber/node()">
		<phoneNumber>
			<type>phone</type>
			<phoneNumber><xsl:value-of select="PhoneNumber"/></phoneNumber>
		</phoneNumber>
		</xsl:if>
		<xsl:if test="FaxNumber/node()">
		<phoneNumber>
			<type>fax</type>
			<phoneNumber><xsl:value-of select="FaxNumber"/></phoneNumber>
		</phoneNumber>
		</xsl:if>
	</phoneNumbers>
</xsl:template>

<xsl:template match="Email">
	<emails>
		<email>
			<type>email</type>
			<email><xsl:value-of select="." /></email>
		</email>
	</emails>
</xsl:template>

<!-- For sort name -->
<xsl:template name="SortName_en">
	
	<xsl:if test="./node()">
		<nameVariants>
			<nameVariant id="{ancestor::item/OrganisationID}_sort_name">
				<type></type>
				<name><xsl:value-of select="." /></name>
			</nameVariant>
		</nameVariants>
	</xsl:if>

</xsl:template>

<!-- For each parent ID - note there can be multiple! -->
<xsl:template match="OrganisationalHierarchy">
	<xsl:for-each select="item">
		<parentOrganisationId><xsl:value-of select="ParentOrganisationID" /></parentOrganisationId>
	</xsl:for-each>
</xsl:template>

<!-- Postal address -->
<xsl:template name="Address">
	<address id="{OrganisationID}_postal_addr">
		<type>postal</type>
		<country><xsl:value-of select="Country" /></country>
		<geospatialPoint><xsl:value-of select="GeoLocationPoint" /></geospatialPoint>
		<displayFormat><xsl:value-of select="AddressLInes" /></displayFormat>
	</address>
</xsl:template>

<xsl:template name="ProfileInfo">
	<profileInfos>
		<profileInfo>
			<type>organisation_profile</type>
			<profileInfo>
				<xsl:call-template name="text">
					<xsl:with-param name="val" select="Profile_en" />
				</xsl:call-template>
			</profileInfo>
		</profileInfo>
	</profileInfos>
</xsl:template>

<!-- Creates a localized string based on the language and country -->
<xsl:template name="text" >
	<xsl:param name="val" />
	<xsl:param name="escape" select="'no'" />
	<xsl:param name="translated" select="'False'" />

	<xsl:variable name="cntry">
		<xsl:choose>
			<xsl:when test="$translated = 'True'"><xsl:value-of select="$country2" /></xsl:when>
			<xsl:otherwise><xsl:value-of select="$country" /></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="lang">
		<xsl:choose>
			<xsl:when test="$translated = 'True'"><xsl:value-of select="$language2" /></xsl:when>
			<xsl:otherwise><xsl:value-of select="$language" /></xsl:otherwise>
		</xsl:choose>		
	</xsl:variable>

	<commons:text lang="{$lang}">
		<xsl:if test="$cntry != ''">
			<xsl:attribute name="country"><xsl:value-of select="$cntry" /></xsl:attribute>
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