<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:css="http://www.w3.org/1996/css"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs"
  version="2.0">
  <xsl:output indent="yes"/>
  <xsl:template match="node()"/>
  <xsl:template match="processing-instruction() | keyword[@role = ('source-type', 'source-application')]/text()" priority="1">
    <xsl:copy-of select="."/>
  </xsl:template>
  <xsl:template match="hub | hub/@* | info | css:rules | css:rule | css:rule/@name | css:rule/@native-name | @role |
                       keywordset | keyword | *[@role]" priority="1">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*"/>
</xsl:stylesheet>