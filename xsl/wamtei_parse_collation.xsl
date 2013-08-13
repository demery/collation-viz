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
            <xd:p>XSLT to parse Walters Art Museum-style collation formulas from Walters TEI
                manuscript descriptions.
            
                Walters-style collation formulae have a form like this:
            
                i, 1(8,-1,2), 2(6), 3(10,-1,9), 4(10,-4,8), 5(6,-1,5), 6(6), 7-11(8), 
                   12(8,-8), 13(8), 14(6), 15(8,-8), 16(12,-5,9,12), 17(10,-6,8,10), 
                   18(10,-6,8,10) 19(8,-7), 20-21(8), i
               
               Here the leading and trailing 'i' indicate a count of flyleaves. Before each 
               parenthetical unit - e.g., '1(8,-1,2)' - is a single quire number (e.g., 1, 2,
               3) or a range of quire numbers (e.g., 7-11, 20-21). Within each parenthetical
               set - e.g., (8,-1,2) - the first number indicates the number of leaves in a 
               theoretical regular quire structure, that would apply if this quire were regular: 
               8 leaves for a regular quire of four bifolia or 6 leaves for a quire of three 
               bifolia. The leaf number is then followed by a series of subtracted positions 
               that explain how the regular quire structure should be altered to derive the 
               structure of the quire in its current form.
               
               The general form of the formula is:
               
                 QUIRE_NO[-QUIRE_NO](LEAF_COUNT[,-POSITION[,POSITION,..]])
               
               For example, '1(8,-1,2)' describes a quire of 6 extant leaves. The quire has 
               two bifolia followed by two singletons. The two bifolia are positions 3+6, 4+5,
               followed by singletons at positions 7, 8. The positions needed to complete the 
               structure are the missing positions 1* and 2* (here marked with a * to indicate
               their absence).

                _ _ _ _ _ _ _ _ 1* 
               |  _ _ _ _ _ _ _ 2*
               | |  ___________ 3
               | | |  _________ 4
               | | | |
               | | | |
               | | | |_________ 5
               | | |___________ 6
               | |_____________ 7
               |_______________ 8
               
               NB The numbers here indicate *theoretical* leaf positions, not folio numbers.
               
               NB Also, these formulae do no describe how the quire came to be, but rather 
               merely describe the structure in a subtractive formula. Nothing should be 
               inferred about the history of the quire from this formula. In the example 
               above, the quire may have been a quire of 4 bifolia to which the last two 
               singletons were later added; the formula is not concerned with this.
               
               This XSLT turns rewrites such a formula in an XML quire structure. The output
               has the following format:
               
                  <quires>
                      <quire n="1" leaves="8"/>
                      <quire n="2" leaves="8">
                          <less>1</less>
                          <less>2</less>
                      </quire>
                      <!--...-->
                  </quires>
            </xd:p>
        </xd:desc>
    </xd:doc>
    
<!--
        TODO: Fix the namespace of output quires structure; now generated under tei:*
        TODO: Handle both added and subtracted leaves (now only subtracted leaves are dealt with.)
        
    -->
    
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
