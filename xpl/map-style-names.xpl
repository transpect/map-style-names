<?xml version="1.0" encoding="utf-8"?>
<p:library 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:bc="http://transpect.le-tex.de/book-conversion"
  xmlns:html="http://www.w3.org/1999/xhtml"
  version="1.0">

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/xproc-util/xslt-mode/xslt-mode.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  <p:import href="http://transpect.le-tex.de/book-conversion/converter/xpl/load-cascaded.xpl"/>

  <p:declare-step name="consolidate-maps" type="css:consolidate-maps">
    <p:input port="source" primary="true" sequence="true">
      <p:documentation>HTML tables where the first column contains system names for styles and the second column contains the
        corresponding user-defined names. A third column may contain comments. </p:documentation>
    </p:input>
    <p:output port="result" primary="true" sequence="true">
      <p:documentation>sequence is true because there may be zero output documents. The normal case is that there ist one
        consolidated map on the output. There will be no more than one output documents on this port.</p:documentation>
    </p:output>

    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>

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
    <letex:store-debug pipeline-step="style-mapping/consolidated-map" extension="xhtml">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>

  </p:declare-step>

  <p:declare-step name="apply-map" type="css:apply-map">
    <p:input port="source" primary="true" sequence="true" select="/*">
      <p:documentation>document with CSSa, where /*/@css:rule-selection-attribute designates the name of the
      @role, @rend, @class, etc. attribute(s) that contain(s) style names.</p:documentation>
    </p:input>
    <p:input port="generating-xsl">
      <p:documentation>XSL stylesheet that generates XSLT from the map</p:documentation>
      <p:document href="../xsl/map2xsl.xsl"/>
    </p:input>
    <p:input port="map">
      <p:documentation>consolidated map, as produced by css:consolidate-maps</p:documentation>
    </p:input>
    <p:output port="result" primary="true"/>
    <p:input port="paths" kind="parameter"/>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:choose>
      <p:xpath-context>
        <p:pipe port="map" step="apply-map"/>
      </p:xpath-context>
      <p:when test="not(//html:table)">
        <p:identity/>
      </p:when>
      <p:otherwise>
        <p:xslt name="stylesheet-from-map">
          <p:input port="source">
            <p:pipe step="apply-map" port="map"/>
          </p:input>
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
        <letex:store-debug pipeline-step="style-mapping/generated" extension="xsl" name="store">
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </letex:store-debug>
        <p:sink/>
        <p:xslt name="apply-generated-xsl">
          <p:input port="source">
            <p:pipe port="source" step="apply-map"/>
          </p:input>
          <p:input port="parameters">
            <p:pipe port="paths" step="apply-map"/>
          </p:input>
          <p:input port="stylesheet">
            <p:pipe port="result" step="stylesheet-from-map"/>
          </p:input>
        </p:xslt>
        <letex:store-debug pipeline-step="style-mapping/completed">
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </letex:store-debug>
      </p:otherwise>
    </p:choose>
    
  </p:declare-step>
  
  <p:declare-step name="map-styles" type="css:map-styles">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>A wrapper for the individual other steps in this library.</p>
    </p:documentation>
    <p:input port="source" primary="true" select="/*">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A document with CSSa, where the /*/@css:rule-selection-attribute designates the name of the @role, @rend, @class, etc.
          attribute(s) that contain(s) style names.</p>
      </p:documentation>
    </p:input>
    <p:input port="paths">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A transpect paths document (<code>c:param-set</code> with certain <code>c:param</code>s that enable cascaded
          loading).</p>
      </p:documentation>
    </p:input>
    <p:output port="result" primary="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>The source document with mapped styles.</p>
      </p:documentation>
    </p:output>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:option name="map-name" required="false" select="'styles/map.xhtml'"/>
    
    <bc:load-whole-cascade name="all-maps">
      <p:with-option name="filename" select="$map-name">
        <p:empty/>
      </p:with-option>
      <p:input port="paths">
        <p:pipe port="paths" step="map-styles"/>
      </p:input>
    </bc:load-whole-cascade>

    <css:consolidate-maps name="consolidate-maps">
      <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
    </css:consolidate-maps>

    <p:sink/>

    <css:apply-map name="apply-map">
      <p:input port="source">
        <p:pipe port="source" step="map-styles"/>
      </p:input>
      <p:input port="map">
        <p:pipe port="result" step="consolidate-maps"/>
      </p:input>
      <p:input port="paths">
        <p:pipe port="paths" step="map-styles"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </css:apply-map>

    <letex:store-debug extension="xhtml" name="store" pipeline-step="style-mapping/processed">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>
    
  </p:declare-step>

</p:library>