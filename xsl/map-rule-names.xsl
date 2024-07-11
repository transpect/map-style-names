<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:css="http://www.w3.org/1996/css"
  version="2.0">
  
  <xsl:param name="map-case-insensitive" select="'no'"/>
  
  <xsl:template match="node() | @*" mode="#default add-css-compat-regex">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:param name="rule-selection-attribute-names" as="xs:string+" 
             select="tokenize((/*/@css:rule-selection-attribute, 'role')[1], '\s+')"/>

  <xsl:variable name="mapping-table" as="element(html:table)?">
    <xsl:apply-templates select="(collection()[2]/descendant::html:table)[1]" mode="add-css-compat-regex"/>
  </xsl:variable>

  <xsl:template match="html:tr[every $cell in *[position() ge 2] satisfies ($cell/self::html:td)]/html:td[2][normalize-space()]">
    <xsl:copy-of select="."/>
    <td xmlns="http://www.w3.org/1999/xhtml">
      <xsl:variable name="parsed">
        <xsl:analyze-string select="." regex="[\[\]]">
          <xsl:matching-substring>
            <sep>
              <xsl:value-of select="."/>
            </sep>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="replace(., '~', '_-_')"/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:variable>
      <xsl:if test="$parsed/text()[preceding-sibling::sep[1] = '['][contains(., '~')]">
        <xsl:message terminate="yes">You can’t use a tilde in a square bracket character list 
          because it will be expanded to '_-_' for being matched against the CSS-compatible name.
        <xsl:sequence select="."/></xsl:message>
      </xsl:if>
      <xsl:value-of select="string-join($parsed, '')"/>
    </td>
  </xsl:template>

  <xsl:variable name="mapping-regexes" as="element(html:td)*"
    select="$mapping-table//html:tr[count(html:td) ge 2]
                                   [every $c in *[position() gt 1] satisfies ($c/self::html:td)]
                            /html:td[2][normalize-space()]"/>
  
  <xsl:variable name="mapping-colors" as="element(html:td)*"
    select="$mapping-table//html:tr[count(html:td) ge 2]
                                   [every $c in *[position() gt 1] satisfies ($c/self::html:td)]
                            /html:td[2][normalize-space()][matches(.,'^#')]"/>

  <xsl:variable name="rules-elements" as="element(css:rules)*" select="//css:rules"/>
  
  <xsl:template match="css:rules">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:for-each select="$mapping-colors">
        <xsl:sequence select="css:create-css-rule(current())"/>
      </xsl:for-each>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="css:create-css-rule" as="element(css:rule)+">
    <xsl:param name="mapping-colors" as="element(html:td)*"/>
    <xsl:element name="css:rule" namespace="http://www.w3.org/1996/css">
      <xsl:attribute name="native-name" select="$mapping-colors/../html:td[1]"/>
      <xsl:choose>
        <xsl:when test="matches($mapping-colors/../html:td[4],'background')">
          <xsl:attribute name="css:background-color" select="$mapping-colors/text()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="css:border-left-color" select="$mapping-colors/text()"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:attribute name="name" select="$mapping-colors/../html:td[1]"/>
    </xsl:element>
  </xsl:function>

  <xsl:template match="css:rule">
    <xsl:variable name="context" as="element(css:rule)" select="."/>
    <xsl:variable name="mapped" as="item()+" select="css:apply-mappings(@name, @native-name, $mapping-regexes, ())"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$mapped[name() = 'name'] = ''">
          <xsl:attribute name="remove" select="@name"/>
        </xsl:when>
        <xsl:when test="not($mapped[name() = 'name'] = @name)">
          <xsl:attribute name="old-name" select="@name"/>
        </xsl:when>
      </xsl:choose>
      <xsl:sequence select="$mapped"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:if test="$mapped[name() = 'name'] = ''">
      <xsl:text>&#xa;             </xsl:text>
      <xsl:comment>Removed css:rule with name '<xsl:value-of select="@name"/>' / native name '<xsl:value-of 
        select="@native-name"/>' because its name was mapped to the empty string.</xsl:comment>
    </xsl:if>
  </xsl:template>

  <xsl:function name="css:apply-mappings" as="item()+">
    <xsl:param name="name" as="attribute(name)"/>
    <xsl:param name="native-name" as="attribute(native-name)?"/>
    <xsl:param name="mapping-regexes" as="element(html:td)*"/>
    <xsl:param name="history" as="comment()*"/>
    <xsl:variable name="mapping-flags" select="if ($map-case-insensitive='yes') then 'i' else ()"/>
    <xsl:choose>
      <xsl:when test="exists($mapping-regexes)">
        <xsl:variable name="apply-current-mapping" as="item()+">
          <xsl:choose>
            <xsl:when test="matches($native-name, $mapping-regexes[1], $mapping-flags)">
              <xsl:variable name="mapped" as="xs:string" 
                select="replace($native-name, $mapping-regexes[1], $mapping-regexes[1]/../html:td[1], $mapping-flags)"/>
              <xsl:attribute name="native-name" select="$mapped"/>
              <xsl:attribute name="name" select="css:escape-native-name($mapped)"/>
              <xsl:comment select="string-join(($mapping-regexes[1], $mapping-regexes[1]/../html:td[1], $mapping-flags), ' → '), '(native-name)'"/>
            </xsl:when>
            <xsl:when test="matches($name, $mapping-regexes[1]/following-sibling::*[1], $mapping-flags)">
              <xsl:attribute name="name"  
                select="css:escape-native-name(
                          replace(
                            $name, 
                            $mapping-regexes[1]/following-sibling::*[1], 
                            $mapping-regexes[1]/../html:td[1],
                            $mapping-flags)
                        )"/>
              <xsl:comment select="string-join(($mapping-regexes[1], $mapping-regexes[1]/following-sibling::*[1], 
                                                $mapping-regexes[1]/../html:td[1]), ' → '), '(name)'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$name, $native-name"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="css:apply-mappings(
                                $apply-current-mapping[name() = 'name'],
                                $apply-current-mapping[name() = 'native-name'], 
                                subsequence($mapping-regexes, 2), 
                                ($history, $apply-current-mapping/self::comment())
                              )"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$name, $native-name, $history"></xsl:sequence>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="css:escape-native-name" as="xs:string?">
    <xsl:param name="input" as="xs:string?"/>
    <xsl:if test="$input">
      <xsl:variable name="strip-builtin-indicator" as="xs:string" select="replace($input, '^.+/', '')"/>
      <xsl:sequence select="replace(
                              replace(
                                replace($strip-builtin-indicator, '~', '_-_'), 
                                '^(\I)', 
                                '_$1'
                              ), 
                              '[^-_a-z0-9]', 
                              '_', 
                              'i'
                            )"/>
    </xsl:if>
  </xsl:function>
  

</xsl:stylesheet>