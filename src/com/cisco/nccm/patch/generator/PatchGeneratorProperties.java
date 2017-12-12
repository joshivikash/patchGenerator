package com.cisco.nccm.patch.generator;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Properties;

import org.apache.log4j.Logger;

public class PatchGeneratorProperties {
    private static final String             DASH_HOME = "DASH_HOME";
    private static final String             JRE_HOME  = "JRE_HOME";
    private String                          dashHome;
    private String                          jreHome;
    private static PatchGeneratorProperties instance;
    private static Logger                   logger;

    static PatchGeneratorProperties getInstance() {
        if (instance == null) {
            instance = new PatchGeneratorProperties();
            instance.init();
        }
        return instance;
    }

    private void init() {
        logger = Logger.getLogger(PatchGeneratorProperties.class);
        Properties properties = new Properties();
        try {
            properties.load(Files.newInputStream(Paths.get("nccmPatchGenerator.properties"), StandardOpenOption.READ));
        } catch (Exception e) {
            logger.error("Error loading patchGenerator.properties", e);
        }
        dashHome = (properties.getProperty(DASH_HOME) != null) ? properties.getProperty(DASH_HOME) : "/var/pari/dash";
        jreHome = (properties.getProperty(JRE_HOME) != null) ? properties.getProperty(JRE_HOME) : "/var/pari/dash/jre";
    }

    public String getDashHome() {
        return dashHome;
    }

    public String getJreHome() {
        return jreHome;
    }
}
