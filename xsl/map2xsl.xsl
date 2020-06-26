<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:xslout="bogo"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>

  <xsl:param name="rule-selection-attribute-names" as="xs:string" select="(/*/@css:rule-selection-attribute, 'role')[1]"/>
  <xsl:param name="remove-border-styles" select="'no'"/>
  <xsl:param name="map-textbox-styles" select="'no'"/>
  <xsl:param name="textbox-style" select="'StylefuerTextfeld'"/>
  <xsl:param name="remove-textboxes" select="'no'"/>
  <xsl:param name="color-mapping" select="'yes'"/>

  <xsl:template match="/">
    <xslout:stylesheet version="2.0">
      <xslout:key name="style-by-name" match="css:rule" use="@name"/> 
      <xslout:variable name="root" as="document-node(element(*))" select="/"/>
      <xslout:variable name="remove-border-styles" select="'{$remove-border-styles}'"/>
      <xslout:variable name="textbox-style" select="'{$textbox-style}'"/>
      <xslout:template match="node() | @*">
        <xslout:copy>
          <xslout:apply-templates select="@*, node()"/>
        </xslout:copy>
      </xslout:template>
      <xslout:template match="css:rule/@old-name"/>
      <xslout:template match="css:rule[@remove]"/>
      <xsl:apply-templates select="descendant::css:rule[@old-name | @remove | @css:border-left-color | @css:background-color]">
        <xsl:with-param name="css:rule-selection-attribute-names" as="xs:string+" 
          select="tokenize($rule-selection-attribute-names, '\s+')"/>
      </xsl:apply-templates>
      <xsl:if test="$map-textbox-styles='yes'">
        <xslout:template match="*:para[descendant::*:phrase[@role='hub:foreign'][w:pict[v:shape/v:textbox]]]">
          <xslout:copy>
            <xslout:if test="normalize-space(string-join(descendant::*:phrase[@role='hub:foreign']/descendant::v:textbox/w:txbxContent[1]/*:para[@role=$textbox-style]/descendant::text(),''))">
              <xslout:attribute name="role" select="normalize-space(string-join(descendant::*:phrase[@role='hub:foreign']/descendant::v:textbox/w:txbxContent[1]/*:para[@role=$textbox-style]/descendant::text(),''))"/>
            </xslout:if>
            <xslout:apply-templates select="@* except @role, node()"/>
          </xslout:copy>
        </xslout:template>
        <xsl:if test="$remove-textboxes =('yes','true')">
          <xslout:template match="*:phrase[@role='hub:foreign'][descendant::v:textbox/w:txbxContent[1]/*:para[@role=$textbox-style]]"/>
        </xsl:if>
      </xsl:if>
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
  
  <xsl:template match="css:rule[@css:border-left-color][$color-mapping = 'yes']" priority="2">
    <xsl:param name="css:rule-selection-attribute-names" as="xs:string+"/>
    <xsl:variable name="border-color" as="xs:string" select="@css:border-left-color"/>
    <xsl:variable name="role" as="xs:string" select="@name"/>
    <xsl:for-each select="$css:rule-selection-attribute-names">
      <xslout:template match="*[not(self::css:rule)][@css:border-left-color = '{$border-color}']">
        <xslout:copy>
          <xslout:attribute name="role" select="'{$role}'"/>
          <xslout:apply-templates select="if ($remove-border-styles=('yes','true')) 
                                          then @* except (@css:border-left-color,@css:border-left-style,@css:border-left-width) 
                                          else @* "/>
          <xslout:apply-templates select="node()"/>
        </xslout:copy>
      </xslout:template>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="css:rule[@css:background-color][$color-mapping = 'yes']" priority="3">
    <xsl:param name="css:rule-selection-attribute-names" as="xs:string+"/>
    <xsl:variable name="background-color" as="xs:string" select="@css:background-color"/>
    <xsl:variable name="role" as="xs:string" select="@name"/>
    <xsl:for-each select="$css:rule-selection-attribute-names">
      <xslout:template match="*[not(self::css:rule)][@css:background-color = '{$background-color}']" priority="1">
        <xslout:copy>
          <xslout:attribute name="role" select="'{$role}'"/>
          <xslout:apply-templates select="if ($remove-border-styles=('yes','true')) 
                                          then @* except (@css:background-color, @css:border-left-color,
                                                          @css:border-left-style,@css:border-left-width) 
                                          else @* "/>
          <xslout:apply-templates select="node()"/>
        </xslout:copy>
      </xslout:template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="css:rule[@remove]">
    <xsl:param name="css:rule-selection-attribute-names" as="xs:string+"/>
    <xsl:variable name="remove" select="@remove" as="xs:string"/>
    <xsl:for-each select="$css:rule-selection-attribute-names">
      <xslout:template match="@{.}[. = '{$remove}']"/>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>