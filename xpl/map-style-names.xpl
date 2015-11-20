<?xml version="1.0" encoding="utf-8"?>
<p:library 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:html="http://www.w3.org/1999/xhtml"
  version="1.0">

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/cascade/xpl/load-cascaded.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />

  <p:declare-step name="consolidate-maps" type="css:consolidate-maps">
    <p:input port="source" primary="true" sequence="true">
      <p:documentation>HTML tables where the first column contains system names for styles and the second column contains the
        corresponding user-defined names. A third column may contain comments. </p:documentation>
    </p:input>
    <p:output port="result" primary="true">
      <p:documentation>If there is no input or if the input doesn’t contain a table, it will be an empty html element.</p:documentation>
    </p:output>

    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:option name="status-dir-uri" required="false" select="'debug/status'"/>
    
    <p:xslt name="consolidating-xsl" template-name="main">
      <p:input port="source">
        <p:documentation>The inline /nodoc serves as a fallback input because the XSLT must have some document for context</p:documentation>
        <p:pipe port="source" step="consolidate-maps"/>
        <p:inline>
          <nodoc/>
        </p:inline>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="../xsl/consolidate-maps.xsl"/>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
    </p:xslt>
    <tr:store-debug pipeline-step="map-style-names/consolidated-map" extension="xhtml">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

  </p:declare-step>

  <p:declare-step name="apply-map" type="css:apply-map">
    <p:input port="source" primary="true" select="/*" >
      <p:documentation>document with CSSa, where /*/@css:rule-selection-attribute designates the name of the
      @role, @rend, @class, etc. attribute(s) that contain(s) style names.</p:documentation>
    </p:input>
    <p:input port="rule-name-mapping-xsl">
      <p:documentation>XSL that parses css-compatible and native style names and maps them
      within css:rules according to the instructions in the map document.</p:documentation>
      <p:document href="../xsl/map-rule-names.xsl"/>
    </p:input>
    <p:input port="generating-xsl">
      <p:documentation>XSL stylesheet that generates XSLT from the map</p:documentation>
      <p:document href="../xsl/map2xsl.xsl"/>
    </p:input>
    <p:input port="map">
      <p:documentation>consolidated map, as produced by css:consolidate-maps</p:documentation>
    </p:input>
    <p:output port="result" primary="true"/>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:option name="status-dir-uri" required="false" select="'debug/status'"/>
    <p:choose>
      <p:xpath-context>
        <p:pipe port="map" step="apply-map"/>
      </p:xpath-context>
      <p:when test="not(//html:table)">
        <p:identity/>
      </p:when>
      <p:otherwise>
        <p:viewport match="css:rules" name="patch-rules">
          <p:output port="result" primary="true"/>
          <p:xslt>
            <p:input port="source">
              <p:pipe port="current" step="patch-rules"/>
              <p:pipe port="map" step="apply-map"/>
            </p:input>
            <p:input port="parameters"><p:empty/></p:input>
            <p:input port="stylesheet">
              <p:pipe port="rule-name-mapping-xsl" step="apply-map"/>
            </p:input>
          </p:xslt>
        </p:viewport>
        <tr:store-debug pipeline-step="map-style-names/map-rule-names" name="store-patched-rules">
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </tr:store-debug>
        <p:xslt name="stylesheet-from-mapped-rules">
          <p:input port="stylesheet">
            <p:pipe port="generating-xsl" step="apply-map"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
          <p:with-param name="rule-selection-attribute-names" select="/*/@css:rule-selection-attribute" cx:type="xs:string">
            <p:pipe port="source" step="apply-map"/>
          </p:with-param>
        </p:xslt>
        <tr:store-debug pipeline-step="map-style-names/generated" extension="xsl" name="store">
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </tr:store-debug>
        <p:sink/>
        <p:xslt name="apply-generated-xsl">
          <p:input port="source">
            <p:pipe port="result" step="patch-rules"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
          <p:input port="stylesheet">
            <p:pipe port="result" step="stylesheet-from-mapped-rules"/>
          </p:input>
        </p:xslt>
        <tr:store-debug pipeline-step="map-style-names/completed">
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </tr:store-debug>
      </p:otherwise>
    </p:choose>
    
  </p:declare-step>
  
  <p:declare-step name="map-styles" type="css:map-styles">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>A wrapper for the individual other steps in this library.</p>
      <p>Here’s an explanation of the style mapping concept:</p>
      <ul>
        <li>The tilde ('~') and the string '_-_' may be used interchangeably in both first columns. They are called “tilde
          metacharacters”.</li>
        <li>Table rows without <code>td</code> will be ignored.</li>
        <li>Otherwise the first <code>td</code> in a row needs to hold the canonical (system) style name, while the second
            <code>td</code> contains the user-defined style name that is found in the actual content and that should be mapped
          to the system name.</li>
        <li>Both names may contain tilde metacharacters.</li>
        <li>The first table in the body will be used for mapping purposes.</li>
        <li>The user style name values in the second column are regular expressions. Likewise, the first column contains
        replacements. You may refer to matching groups by <code>$1</code>, <code>$2</code>, etc.</li>
        <li>All mappings will be applied to each style, sequentially from top to bottom.</li>
        <li>A given mapping instruction will first be tested against css:rule/@native-name then against css:rule/@name. 
          If native-name matches, the replacement is taken from first column and applied to native-name. The name attribute
        will then be generated from the updated native-name attribute.</li>
        <li>The comment column is irrelevant to the mapping process.</li>
        <li>If there are multiple style maps in a configuration hierarchy, they will be merged. If the system names of two rows
          match, the row from the more specific map file will win.</li>
        <li>The merged file will appear in the debug dir als map-style-names/consolidated-map.xhtml. It will contain provenance
          information in the first, all-<code>th</code> column, as links to the source map file for each rule.</li>
      </ul>
    </p:documentation>
    <p:input port="source" primary="true" sequence="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A document (or douments) with CSSa, where the /*/@css:rule-selection-attribute designates the name of the @role, @rend, @class, etc.
          attribute(s) that contain(s) style names.</p>
      </p:documentation>
    </p:input>
    <p:input port="paths" kind="parameter" primary="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A transpect paths document (<code>c:param-set</code> with certain <code>c:param</code>s that enable cascaded
          loading).</p>
      </p:documentation>
    </p:input>
    <p:output port="result" primary="true" sequence="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>The source document(s) with mapped styles.</p>
      </p:documentation>
    </p:output>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:option name="map-name" required="false" select="'styles/map.xhtml'"/>
    <p:option name="status-dir-uri" required="false" select="'debug/status'"/>
    
    <tr:load-whole-cascade name="all-maps" order="most-specific-first">
      <p:with-option name="filename" select="$map-name">
        <p:empty/>
      </p:with-option>
      <p:input port="paths">
        <p:pipe port="paths" step="map-styles"/>
      </p:input>
    </tr:load-whole-cascade>

    <css:consolidate-maps name="consolidate-maps">
      <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
    </css:consolidate-maps>

    <p:sink/>

    <p:for-each name="iter">
      <p:iteration-source select="/*">
        <p:pipe port="source" step="map-styles"/>
      </p:iteration-source>
      <css:apply-map name="apply-map">
        <p:input port="source">
          <p:pipe port="current" step="iter"/>
        </p:input>
        <p:input port="map">
          <p:pipe port="result" step="consolidate-maps"/>
        </p:input>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </css:apply-map>
      <tr:store-debug name="store">
        <p:with-option name="pipeline-step" select="concat('map-style-names/', replace(base-uri(), '^.+/(.+?)(\..+)?', '$1'), '.processed')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
    </p:for-each>

    
  </p:declare-step>

</p:library>