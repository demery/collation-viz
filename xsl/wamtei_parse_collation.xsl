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
                <xsl:call-template name="quire-set">
                    <xsl:with-param name="quire-set" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </quires>
    </xsl:template>
    
    <xsl:template name="quire-set">
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
        <xsl:variable name="size" select="tokenize(.,'[()]')[2]"/>
        <xsl:call-template name="quires">
            <xsl:with-param name="start-quire" select="$start"/>
            <xsl:with-param name="end-quire" select="$end"/>
            <xsl:with-param name="quire-size" select="$size"/>
        </xsl:call-template>   
    </xsl:template>
    
    <xsl:template name="quires">
        <xsl:param name="start-quire" as="xs:double"/>
        <xsl:param name="end-quire" as="xs:double"/>
        <xsl:param name="quire-size"/>
        <xsl:if test="$start-quire &lt; ($end-quire + 1)">
            <quire>
                <xsl:attribute name="n" select="$start-quire"/>
                <xsl:attribute name="leaves" select="$quire-size"/>
            </quire>
            <xsl:variable name="next-quire" select="$start-quire + 1" as="xs:double"/>
            <xsl:call-template name="quires">
                <xsl:with-param name="start-quire" select="$next-quire"/>
                <xsl:with-param name="end-quire" select="$end-quire"/>
                <xsl:with-param name="quire-size" select="$quire-size"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>