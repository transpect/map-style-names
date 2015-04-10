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

  <xsl:param name="rule-selection-attribute-names" as="xs:string" select="'role'"/>

  <xsl:template match="/">
    <xsl:apply-templates select="(descendant::html:table)[1]"/>
  </xsl:template>

  <xsl:template match="html:table">
    <xslout:stylesheet version="2.0">
      <!-- For Hub format, detect whether docx was created with LibreOffice or Word.
      We used matches here because surprisingly, @role = 'source-application' threw an error 
      in both oXygen 16.1 and Calabash 1.0.25-95 -->
      <xslout:variable name="application" as="xs:string"
        select="(/*/*:info/*:keywordset/*:keyword[matches(@role, 'source-application')], 'Microsoft Office Word')[1]"/>
      <xslout:variable name="cssa-orig-attname" as="xs:string" 
        select="if (($application) = 'Microsoft Office Word')
                then 'native-name'
                else 'name'"/>
      <xslout:key name="style-by-name" match="css:rule" use="@name"/> 
      <xslout:variable name="root" as="document-node(element(*))" select="/"/>
      <xslout:template match="node() | @*">
        <xslout:copy>
          <xslout:apply-templates select="@*, node()"/>
        </xslout:copy>
      </xslout:template>
      <xsl:apply-templates select="descendant::html:tr">
        <xsl:with-param name="css:rule-selection-attribute-names" as="xs:string+" 
          select="tokenize($rule-selection-attribute-names, '\s+')"/>
      </xsl:apply-templates>
    </xslout:stylesheet>
  </xsl:template>

  <xsl:template match="html:tr[td][not(every $c in *[position() gt 1] satisfies ($c/self::html:td)) or count(html:td) lt 2]">
    <xsl:message>Unrecognized mapping instruction <xsl:sequence select="."/> in <xsl:value-of select="base-uri()"/></xsl:message>
  </xsl:template>

  <xsl:template match="html:tr[th][every $c in * satisfies ($c/self::th)]">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="html:tr">
    <xsl:param name="css:rule-selection-attribute-names" as="xs:string+"/>
    <xsl:variable name="user-stylename-regex" as="xs:string" select="css:create-regex(html:td[2])"/>
    <xsl:variable name="target-stylename" as="xs:string" select="css:escape-name(html:td[1])"/>
    <xsl:variable name="pos" as="xs:integer" select="position()"/>
    <xslout:template match="css:rule/@name[matches((../@*[name() = $cssa-orig-attname], .)[1], '{$user-stylename-regex}')]">
      <xslout:attribute name="{{name()}}" select="replace((../@*[name() = $cssa-orig-attname], .)[1], '{$user-stylename-regex}', '{$target-stylename}$2')"/>
    </xslout:template>  
    <xsl:for-each select="$css:rule-selection-attribute-names">
      <xslout:template match="@{.}[matches(key('style-by-name', ., $root)/(@*[name() = $cssa-orig-attname], @name)[1], '{$user-stylename-regex}')]" priority="{$pos}">
        <xslout:variable name="name-for-replacement" as="xs:string"
          select="key('style-by-name', .)/(@*[name() = $cssa-orig-attname], @name)[1]"/>
        <xslout:variable name="tmp" as="attribute(*)">
          <xslout:attribute name="{{name()}}" 
            select="replace($name-for-replacement, '{$user-stylename-regex}', '')"/> 
        </xslout:variable>
        <xslout:variable name="tmp2" as="attribute(*)">
          <xslout:apply-templates select="$tmp"/>
        </xslout:variable>
        <xslout:attribute name="{{name()}}" select="normalize-space(string-join((replace($name-for-replacement, '^.*{$user-stylename-regex}.*$', '{$target-stylename}$2'), $tmp2[normalize-space()]),' '))"/>
      </xslout:template>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:function name="css:escape-name" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="replace(replace(replace($name, '~', '_-_'), '[^-_a-z0-9]', '_', 'i'), '^(\I)', '_$1')"/>
  </xsl:function>

  <xsl:function name="css:create-regex" as="xs:string">
    <xsl:param name="base-stylename" as="xs:string"/>
    <xsl:sequence select="concat('(^|\s+)', css:escape-name($base-stylename), '(\s+|_-_\S*|$)')"/>
  </xsl:function>

</xsl:stylesheet>