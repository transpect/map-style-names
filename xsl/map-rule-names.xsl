<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:css="http://www.w3.org/1996/css"
  version="2.0">
  
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

  <xsl:variable name="rules-elements" as="element(css:rules)*" select="//css:rules"/>

  <xsl:template match="css:rule">
    <xsl:variable name="context" as="element(css:rule)" select="."/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="mapped" as="item()+" select="css:apply-mappings(@name, @native-name, $mapping-regexes, ())"/>
      <xsl:if test="not($mapped[name() = 'name'] = @name)">
        <xsl:attribute name="old-name" select="@name"/>
      </xsl:if>
      <xsl:sequence select="$mapped"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="css:apply-mappings" as="item()+">
    <xsl:param name="name" as="attribute(name)"/>
    <xsl:param name="native-name" as="attribute(native-name)?"/>
    <xsl:param name="mapping-regexes" as="element(html:td)*"/>
    <xsl:param name="history" as="comment()*"/>
    <xsl:choose>
      <xsl:when test="exists($mapping-regexes)">
        <xsl:variable name="apply-current-mapping" as="item()+">
          <xsl:choose>
            <xsl:when test="matches($native-name, $mapping-regexes[1])">
              <xsl:variable name="mapped" as="xs:string" 
                select="replace($native-name, $mapping-regexes[1], $mapping-regexes[1]/../html:td[1])"/>
              <xsl:attribute name="native-name" select="$mapped"/>
              <xsl:attribute name="name" select="css:escape-native-name($mapped)"/>
              <xsl:comment select="string-join(($mapping-regexes[1], $mapping-regexes[1]/../html:td[1]), ' → '), '(native-name)'"/>
            </xsl:when>
            <xsl:when test="matches($name, $mapping-regexes[1]/following-sibling::*[1])">
              <xsl:attribute name="name"  
                select="css:escape-native-name(
                          replace(
                            $name, 
                            $mapping-regexes[1]/following-sibling::*[1], 
                            $mapping-regexes[1]/../html:td[1]
                          )
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
  
  <!--<xsl:variable name="topmost-rule-scopes" as="element(*)*">
    <xsl:variable name="rules-ancestors" as="element(rule-ancestor)*">
      <xsl:for-each select="$rules-elements/ancestor::*">
        <xsl:variable name="current-ancestor" as="element(*)" select="."/>
        <rule-ancestor depth="{count(ancestor::*)}">
          <xsl:attribute name="rules-element-ids" separator=" " 
            select="for $rs in $rules-elements[some $a in ancestor::* satisfies ($a is $current-ancestor)]
                    return generate-id($rs)">
          </xsl:attribute>
        </rule-ancestor>
      </xsl:for-each>
    </xsl:variable>
  </xsl:variable>--> 


</xsl:stylesheet>