<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml" 
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="xs html tr"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <xsl:variable name="htmldocs" select="collection()[//table]" as="document-node(element(html))*"/>
  
  <xsl:template name="main">
    <!-- Transform the first (most specific) document in the default collection() that has been loaded 
      by tr:load-whole-cascade (with order=most-specific-first). All the documents are supposed to be XHTML 1.0 documents 
      that provide style name mappings. The table rows within a documents are expected to be sorted by
      decreasing specificity. When an element with the same ID is present in a more specific document, this 
      more specific element will be used. -->
    <xsl:choose>
      <xsl:when test="$htmldocs">
        <xsl:apply-templates select="$htmldocs[1]" mode="resolve-cascade"/>
      </xsl:when>
      <xsl:otherwise>
        <html/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="tr[count(td)=1][td[every $el in * satisfies $el[self::a[@href]]]]" mode="resolve-txt">
    <xsl:variable name="path" select="resolve-uri(descendant::a[1]/@href, base-uri())"/>
      <xsl:variable name="txt" select="unparsed-text($path)"/>
      <xsl:for-each select="tokenize($txt,'&#xa;')">
        <tr  rel="{$path}">
          <xsl:for-each select="tokenize(current(),'&#x9;')">
            <xsl:sort select="tr:td-order(current())" order="ascending"/>
            <td>
              <xsl:sequence select="if (matches(current(),'^[0-9A-Z]+$')) then concat('#',current()) else normalize-space(current())"/>
            </td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
  </xsl:template>
  
  <xsl:function name="tr:td-order" as="xs:integer">
    <xsl:param name="td-text"/>
    <xsl:choose>
      <xsl:when test="matches($td-text,'^[0-9A-Z]+$')">
        <xsl:sequence select="2"/>
      </xsl:when>
      <xsl:when test="matches($td-text,'^false$|^true$|^border$|^background$')">
        <xsl:sequence select="3"/>
      </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="1"/>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="@rel" mode="resolve-cascade"/>
  
  <xsl:template match="table[. is (//table)[1]]" mode="resolve-cascade">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:variable name="resolve-txt-trs">
        <xsl:apply-templates select="$htmldocs//table[. is (//table)[1]]//tr[count(td)=1][td[every $el in * satisfies $el[self::a[@href]]]]" mode="resolve-txt"/>
      </xsl:variable>
      <xsl:variable name="all-trs" as="element(tr)+" 
        select="$htmldocs//table[. is (//table)[1]]
                          //tr[every $c in *[position() gt 1] satisfies ($c/self::html:td) and count(html:td) ge 2],
                $resolve-txt-trs/*"/>
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
      <xsl:for-each-group group-by="td[2]" select="$all-trs">
        <xsl:sort select="html:tr-class-order(@class)" order="ascending"/>
        <xsl:variable name="first" as="element(html:tr)" 
          select="if (@class = 'initial') then current-group()[last()] else current-group()[1]"/>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <th><a href="{if (@rel) then @rel else base-uri($first)}"><xsl:value-of select="if (@rel) then replace(@rel,'.*/(.+).txt$','$1') else replace(base-uri($first), '^.+/+(.+?)/+.+?/+.+?\.x?html#?$', '$1')"/></a></th>
          <xsl:copy-of select="$first/td"/>
          <xsl:for-each select="count($first/td) + 1 to $max-row-length">
            <td/>
          </xsl:for-each>
        </xsl:copy>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="html:tr-class-order" as="xs:integer">
    <xsl:param name="class" as="attribute(class)?"/>
    <xsl:variable name="s9y" as="xs:integer" 
      select="if (empty($class)) then 0 
              else index-of(for $h in $htmldocs return string(base-uri($h)), string(base-uri(root($class))))"/>
    <xsl:choose>
      <xsl:when test="$class = 'initial'">
        <!-- most generic (last document) will be sorted first when sorting in ascending order -->
        <xsl:sequence select="- $s9y"/>
      </xsl:when>
      <xsl:when test="$class = 'final'">
        <xsl:sequence select="count($htmldocs) - $s9y + 1"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- no (or other) class -->
        <xsl:sequence select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="* | @*" mode="resolve-cascade resolve-txt">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>