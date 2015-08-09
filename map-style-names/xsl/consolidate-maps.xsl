<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml" 
  exclude-result-prefixes="xs html"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <xsl:variable name="htmldocs" select="collection()[//table]" as="document-node(element(html))*"/>
  
  <xsl:template name="main">
    <!-- Transform the last (most specific) document in the default collection() that has been loaded 
      by transpect:load-whole-cascade. All the documents are supposed to be XHTML 1.0 documents 
      that provide style name mappings. The table rows within a documents are expected to be sorted by
      decreasing specificity. When an element with the same ID is present in a more specific document, this 
      more specific element will be used. -->
    <xsl:message select="'CCCCCCCCCCCCCCCCCCCCCC ', exists($htmldocs//table), string-join(reverse(collection())/base-uri(), ' ')"></xsl:message>
    <xsl:choose>
      <xsl:when test="$htmldocs">
        <xsl:apply-templates select="$htmldocs[1]" mode="resolve-cascade"/>
      </xsl:when>
      <xsl:otherwise>
        <html/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="table[. is (//table)[1]]" mode="resolve-cascade">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:variable name="all-trs" as="element(tr)+" 
        select="$htmldocs//table[. is (//table)[1]]
                           //tr[every $c in *[position() gt 1] satisfies ($c/self::html:td) and count(html:td) ge 2]"/>
      <xsl:variable name="max-row-length" as="xs:integer" select="xs:integer(max(for $tr in $all-trs return count($tr/td)))"/>
      <xsl:for-each select="descendant::tr[th][every $c in * satisfies ($c/self::th)]">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <th/>
          <xsl:copy-of select="th"/>
          <xsl:for-each select="count(th) + 1 to $max-row-length">
            <th/>
          </xsl:for-each>
        </xsl:copy>
      </xsl:for-each>
      <xsl:for-each-group group-by="td[2]" select="reverse($all-trs)">
        <xsl:variable name="first" select="current-group()[1]" as="element(tr)"/>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <th><a href="{base-uri($first)}"><xsl:value-of select="replace(base-uri($first), '^.+/+(.+?)/+.+?/+.+?\.x?html#?$', '$1')"/></a></th>
          <xsl:copy-of select="$first/td"/>
          <xsl:for-each select="count($first/td) + 1 to $max-row-length">
            <td/>
          </xsl:for-each>
        </xsl:copy>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="* | @*" mode="resolve-cascade">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>