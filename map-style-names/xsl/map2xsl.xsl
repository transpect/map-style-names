<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xslout="bogo"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>

  <xsl:param name="rule-selection-attribute-names" as="xs:string" select="(/*/@css:rule-selection-attribute, 'role')[1]"/>

  <xsl:template match="/">
    <xslout:stylesheet version="2.0">
      <xslout:key name="style-by-name" match="css:rule" use="@name"/> 
      <xslout:variable name="root" as="document-node(element(*))" select="/"/>
      <xslout:template match="node() | @*">
        <xslout:copy>
          <xslout:apply-templates select="@*, node()"/>
        </xslout:copy>
      </xslout:template>
      <xslout:template match="css:rule/@old-name"/>
      <xsl:apply-templates select="descendant::css:rule[@old-name]">
        <xsl:with-param name="css:rule-selection-attribute-names" as="xs:string+" 
          select="tokenize($rule-selection-attribute-names, '\s+')"/>
      </xsl:apply-templates>
    </xslout:stylesheet>
  </xsl:template>

  <xsl:template match="css:rule[@old-name]">
    <xsl:param name="css:rule-selection-attribute-names" as="xs:string+"/>
    <xsl:variable name="old-name" as="xs:string" select="@old-name"/>
    <xsl:variable name="new-name" as="xs:string" select="@name"/>
    <xsl:for-each select="$css:rule-selection-attribute-names">
      <xslout:template match="@{.}[tokenize(., '\s+') = '{$old-name}']">
        <xslout:attribute name="{{name()}}" separator=" ">
          <xslout:for-each select="tokenize(., '\s+')">
            <xslout:choose>
              <xslout:when test=". = '{$old-name}'">
                <xslout:sequence select="'{$new-name}'"/>
              </xslout:when>
              <xslout:otherwise>
                <xslout:sequence select="."/>
              </xslout:otherwise>
            </xslout:choose>
          </xslout:for-each>
        </xslout:attribute>
      </xslout:template>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>