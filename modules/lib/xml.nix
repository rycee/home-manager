{ saxon-he, runCommand }:

rec {
  genXMLFile = input:
    runCommand "generated-xml" {
      input = builtins.toXML input;

      stylesheet = builtins.toFile "stylesheet.xsl" ''
        <?xml version='1.0' encoding='UTF-8'?>
        <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='3.0'>
          <xsl:output method="xml" indent="yes" />
          <xsl:template match='attrs[attr[@name="name"]]'>
            <xsl:element name='{attr[@name="name"]/string/@value}'>
              <xsl:for-each select='attr[@name="attrs"]/attrs/*'>
                <xsl:attribute name='{@name}'>
                  <xsl:value-of select='string/@value' />
                </xsl:attribute>
              </xsl:for-each>
              <xsl:apply-templates select='attr[@name="children"]/list/*' />
              <xsl:value-of select='attr[@name="content"]/string/@value' />
            </xsl:element>
          </xsl:template>
        </xsl:stylesheet>
      '';
    } ''
      echo "$input" | ${saxon-he}/bin/saxon-he - $stylesheet > $out
    '';
  genXML = input: builtins.readFile (genXMLFile input);
}
