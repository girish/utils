<?xml version="1.0" encoding="utf-8"?>
<!-- 
	XSLT for wiki2xml

	usage: /usr/bin/xsltproc xhtml.xslt yourfile.xml

	Given a wiki syntax article, use wiki2xml by Magnus Manke to convert it
	as a XML document. Save the XML in a file (ex: yourfile.xml) then launch
	xlstproc that will happylly apply this stylesheet to the xml document
	and output some XHTML.


	Author:
		Ashar Voultoiz <hashar@altern.org
	License:
	http://www.gnu.org/copyleft/gpl.html GNU General Public Licence 2.0 or later

	Copyright © 2006 Ashar Voultoiz

-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
	method="html" indent="yes"
	encoding="utf-8"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
/>

<xsl:template match="/">
	<xsl:apply-templates />
</xsl:template>

<xsl:template match="/articles">
	<xsl:apply-templates />
</xsl:template>

<xsl:template match="/articles/article">
<html>
<head>
	<title><xsl:value-of select="@title" /></title>
	<style type="text/css" media="screen,projection">@import "http://en.wikipedia.org/w/skins-1.5/monobook/main.css";</style>
</head>
<body class="ns-0 ltr">
<div id="globalWrapper">
	<div id="column-content">
		<div id="content">
		<h1 class="firstHeading"><xsl:value-of select="@title" /></h1>
			<div id="bodyContent">
			<h3 id="siteSub">Generated with xhtml.xslt</h3>
			<div id="contentSub"></div>
			</div>
		<xsl:apply-templates />
		</div>
	</div>
</div>
</body>
</html>
</xsl:template>

<xsl:template match="paragraph">
	<p><xsl:apply-templates /></p>
</xsl:template>

<xsl:template match="list">
	<xsl:choose>
		<xsl:when test="@type = numbered">
		<ol><xsl:apply-templates/></ol>
		</xsl:when>
		<xsl:when test="@type = bullet">
		<ul><xsl:apply-templates/></ul>
		</xsl:when>
		<xsl:otherwise>
		<ul><xsl:apply-templates/></ul>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="listitem">
<li><xsl:apply-templates /></li>
</xsl:template>

<xsl:template match="space">
<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text><xsl:apply-templates />
</xsl:template>

<xsl:template match="italics">
<i><xsl:apply-templates /></i>
</xsl:template>

<xsl:template match="link">
	<xsl:choose>
		<xsl:when test="@type='external'" >
			<xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text><xsl:value-of select="@href" />
			<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text disable-output-escaping="yes">&lt;a href="http://yourhost/wiki/</xsl:text>
			<xsl:apply-templates select="target"/>
			<xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
			<xsl:choose>
				<xsl:when test="child::part">
					<xsl:apply-templates select="part"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="target"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="target">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="part">
<xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>
