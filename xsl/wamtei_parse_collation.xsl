<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Aug 12, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Doug Emery</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output indent="yes"/>
    <xsl:template match="/">
        <quires>
            <xsl:variable name="collation" select="//tei:formula"/>
            <xsl:text>&#xA;</xsl:text>
            <xsl:comment>
                <xsl:text>Formula: </xsl:text>
                <xsl:value-of select="$collation"/>
            </xsl:comment>
            <xsl:variable name="quire-string" select="replace($collation, '^\s*[ivxl]+\s*,\s*|,\s*[ivxl]+$*', '')"/>
            <xsl:text>&#xA;</xsl:text>
            <xsl:comment>
                <xsl:text>Quire string: </xsl:text>
                <xsl:value-of select="$quire-string"/>
            </xsl:comment>
            <xsl:for-each select="tokenize($quire-string, '\),\s*')">
                <xsl:call-template name="parse-quire-set">
                    <xsl:with-param name="quire-set" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </quires>
    </xsl:template>
    
    <xsl:template name="parse-quire-set">
        <xsl:param name="quire-set"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:variable name="quire-nos" select="tokenize(.,'\(')[1]"/>
        <xsl:variable name="start" select="number(tokenize($quire-nos,'-')[1])"/>
        <xsl:variable name="tmp_end" select="number(tokenize($quire-nos,'-')[2])"/>
        <xsl:variable name="end">
            <xsl:choose>
                <xsl:when test="string($tmp_end) = 'NaN'">
                    <xsl:value-of select="$start"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$tmp_end"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="quire-spec" select="tokenize(.,'[()]')[2]"/>
        <xsl:call-template name="parse-quires">
            <xsl:with-param name="start-quire" select="$start"/>
            <xsl:with-param name="end-quire" select="$end"/>
            <xsl:with-param name="quire-spec" select="$quire-spec"/>
        </xsl:call-template>   
    </xsl:template>
    
    <xsl:template name="parse-quires">
        <xsl:param name="start-quire" as="xs:double"/>
        <xsl:param name="end-quire" as="xs:double"/>
        <xsl:param name="quire-spec"/>
        <xsl:if test="$start-quire &lt; ($end-quire + 1)">
            <quire>
                <xsl:attribute name="n" select="$start-quire"/>
                <xsl:attribute name="leaves">
                    <xsl:call-template name="parse-leaves">
                        <xsl:with-param name="quire-spec" select="$quire-spec"/>
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="parse-alterations">
                    <xsl:with-param name="quire-spec" select="$quire-spec"/>
                </xsl:call-template>
            </quire>
            <xsl:variable name="next-quire" select="$start-quire + 1" as="xs:double"/>
            <xsl:call-template name="parse-quires">
                <xsl:with-param name="start-quire" select="$next-quire"/>
                <xsl:with-param name="end-quire" select="$end-quire"/>
                <xsl:with-param name="quire-spec" select="$quire-spec"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="parse-leaves">
        <xsl:param name="quire-spec"/>
        <xsl:value-of select="tokenize(normalize-space($quire-spec), ', *')[1]"/>        
    </xsl:template>
    
    <xsl:template name="parse-alterations">
        <xsl:param name="quire-spec"/>
        <xsl:variable name="normal-spec" select="replace(normalize-space($quire-spec), '\s+','')"/>
        <xsl:if test="matches($normal-spec, ',')">
            <xsl:for-each select="tokenize(substring-after($normal-spec, ','), ',')">
                <less>
                    <xsl:value-of select="replace(., '^-', '')"/>
                </less>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>