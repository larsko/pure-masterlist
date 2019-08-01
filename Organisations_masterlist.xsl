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

		<visibility>
			<xsl:choose>
				<xsl:when test="Visibility/node()"><xsl:value-of select="Visibility" /></xsl:when>
				<xsl:otherwise>Public</xsl:otherwise>
			</xsl:choose>
		</visibility>

		<xsl:apply-templates select="OrganisationalHierarchy" />	


		<xsl:if test="Profile_en/node() | Profile_translated/node()">
			<xsl:call-template name="ProfileInfo" />
		</xsl:if>

		<xsl:if test="PhoneNumber/node() | FaxNumber/node()">
			<xsl:call-template name="Numbers" />
		</xsl:if>

		<xsl:apply-templates select="Email" />

		<xsl:if test="WebsiteURL_en/node() | WebsiteURL_translated/node()">
			<xsl:call-template name="Website" />
		</xsl:if>
	
		<xsl:call-template name="Address" />

	</organisation>

</xsl:template>

<!-- phone and fax -->
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

<!-- email -->
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

<!-- Website -->
<xsl:template name="Website">
	<webAddresses>
		<webAddress>
		<type>web</type>

		<xsl:if test="WebsiteURL_en/node()">
			<webAddress>
				<xsl:call-template name="text">
					<xsl:with-param name="val" select="WebsiteURL_en" />
				</xsl:call-template>
			</webAddress>
		</xsl:if>

		<xsl:if test="WebsiteURL_translated/node() and $translated='True'">
			<webAddress>
				<xsl:call-template name="text">
					<xsl:with-param name="val" select="WebsiteURL_translated" />
					<xsl:with-param name="translated" select="$translated" />
				</xsl:call-template>
			</webAddress>
		</xsl:if>

		</webAddress>
	</webAddresses>	
</xsl:template>

<!-- Postal address -->
<xsl:template name="Address">
	<xsl:if test="Country | GeoLocationPoint | AddressLInes">
		<addresses>
			<address id="{OrganisationID}_postal_addr">
				<type>postal</type>
				<xsl:if test="Country">
					<country><xsl:value-of select="Country" /></country>
				</xsl:if>
				<xsl:if test="GeoLocationPoint">
					<geospatialPoint><xsl:value-of select="GeoLocationPoint" /></geospatialPoint>
				</xsl:if>
				<xsl:if test="AddressLInes">
					<displayFormat><xsl:value-of select="AddressLInes" /></displayFormat>
				</xsl:if>
			</address>
		</addresses>
	</xsl:if>
</xsl:template>


<!-- profile info -->
<xsl:template name="ProfileInfo">
	<profileInfos>
		<profileInfo>
			<type>organisation_profile</type>
			<xsl:if test="Profile_en/node()">
				<profileInfo>
					<xsl:call-template name="text">
						<xsl:with-param name="val" select="Profile_en" />
					</xsl:call-template>
				</profileInfo>
			</xsl:if>
			<xsl:if test="Profile_translated/node() and $translated='True'">
				<profileInfo>
					<xsl:call-template name="text">
						<xsl:with-param name="val" select="Profile_translated" />
						<xsl:with-param name="translated" select="$translated" />
					</xsl:call-template>
				</profileInfo>
			</xsl:if>
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