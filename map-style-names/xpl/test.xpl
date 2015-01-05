<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:html="http://www.w3.org/1999/xhtml"
  name="test"
  version="1.0">

  
  <p:input port="source" primary="true" sequence="true"/>
  <p:input port="paths" />
  <p:output port="result" primary="true" sequence="true"/>
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.le-tex.de/map-style-names/xpl/map-style-names.xpl"/>
  
  <css:map-styles name="map-styles">
    <p:input port="paths">
      <p:pipe port="paths" step="test"/>
    </p:input>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </css:map-styles>
  
  
</p:declare-step>