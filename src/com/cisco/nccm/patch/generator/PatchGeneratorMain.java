package com.cisco.nccm.patch.generator;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

import org.apache.commons.io.FileUtils;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

public class PatchGeneratorMain {

    private static Logger       logger  = Logger.getLogger(PatchGeneratorMain.class);
    private static ZipFile      zipFile = null;
    private static List<String> lines;
    private static List<String> filesCopiedToZip;
    private static Path         catalogueFilePath;

    public static void main(String[] args) {
        if (args.length != 2) {
            System.out.println("Usage : java -jar nccm-patch-generator-<version>.jar <file1.zip> <catalogue.csv>");
            return;
        }
        init(args[0], args[1]);
    }

    private static void init(String fileZip, String catalogueFile) {
        PropertyConfigurator.configure("log4j.properties");
        try {
            catalogueFilePath = Paths.get(catalogueFile);
            if (!Files.exists(catalogueFilePath)) {
                throw new Exception("Catalogue File doesn't exist");
            }
            zipFile = new ZipFile(fileZip);
            Files.deleteIfExists(Paths.get("ServerPatch.zip"));
            Path folderPath = Paths.get("ServerPatch");
            if (folderPath.toFile().exists()) {
                FileUtils.deleteDirectory(folderPath.toFile());
            }
            Files.createDirectories(folderPath);
            lines = Files.lines(catalogueFilePath).collect(Collectors.toList());
            filesCopiedToZip = new ArrayList<String>();
            copyFilesToPatchFolder();
        } catch (Exception e) {
            logger.error("Error while initialization", e);
        }
    }

    private static void copyFilesToPatchFolder() {
        InputStream inputStream = null;
        try {
            Enumeration<? extends ZipEntry> entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                ZipEntry zipEntry = (ZipEntry) entries.nextElement();
                boolean isModifiedOrAdded = lines.stream().anyMatch((line) -> {
                    return (line.equals("M," + zipEntry.getName()) || line.equals("A," + zipEntry.getName()));
                });
                if (isModifiedOrAdded) {
                    inputStream = zipFile.getInputStream(zipEntry);
                    String[] folderStructure = zipEntry.getName().split("/");
                    String previousFolder = "ServerPatch/";
                    for (int i = 0; i < folderStructure.length - 1; i++) {
                        Path folderPath = Paths.get(previousFolder + File.separator + folderStructure[i]);
                        if (!Files.exists(folderPath)) {
                            Files.createDirectories(folderPath);
                        }
                        previousFolder += File.separator + folderStructure[i];
                    }
                    Files.copy(inputStream, Paths.get("ServerPatch/" + zipEntry.getName()),
                            StandardCopyOption.REPLACE_EXISTING);
                    inputStream.close();
                    filesCopiedToZip.add(zipEntry.getName());
                }
            }
            zipPatchFolder();
        } catch (Exception e) {
            logger.error("Error while copying Files to Patch folder", e);
            if (inputStream != null) {
                try {
                    inputStream.close();
                } catch (Exception ee) {
                    logger.error("Copying files from zip to Patch Folder. Error closing input stream", ee);
                }
            }
        }
    }

    private static void zipPatchFolder() {
        try {
            FileOutputStream fileOutputStream = new FileOutputStream("ServerPatch.zip");
            ZipOutputStream zipOutputStream = new ZipOutputStream(fileOutputStream);
            Path folder = Paths.get("ServerPatch");
            Files.walkFileTree(folder, new SimpleFileVisitor<Path>() {
                @Override
                public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                    try {
                        zipOutputStream.putNextEntry(new ZipEntry(folder.relativize(file).toString()));
                        Files.copy(file, zipOutputStream);
                        zipOutputStream.closeEntry();
                        return FileVisitResult.CONTINUE;
                    } catch (Exception e) {
                        logger.error("Error adding file to zip", e);
                    }
                    return FileVisitResult.CONTINUE;
                }

                @Override
                public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
                    try {
                        zipOutputStream.putNextEntry(new ZipEntry(folder.relativize(dir).toString() + File.separator));
                        zipOutputStream.closeEntry();
                        return FileVisitResult.CONTINUE;
                    } catch (Exception e) {
                        logger.error("Error adding folder to zip", e);
                    }
                    return FileVisitResult.CONTINUE;
                }
            });
            zipOutputStream.flush();
            zipOutputStream.close();
            fileOutputStream.flush();
            fileOutputStream.close();
            deleteAllEntriesExceptDeletedFilesFromCatalogueFile();
        } catch (Exception e) {
            logger.error("Error while zipping Patch folder", e);
        }
    }

    private static void deleteAllEntriesExceptDeletedFilesFromCatalogueFile() {
        try {
            List<String> remainingFiles = lines.stream().filter((line) -> {
                return !filesCopiedToZip.contains(line.substring(2)) && !line.startsWith("Status");
            }).collect(Collectors.toList());
            Path instructions = Paths.get("instructions.txt");
            if (!Files.exists(instructions)) {
                Files.createFile(instructions);
            }
            List<String> commands = new ArrayList<String>();
            remainingFiles.forEach((fileToBeDeleted) -> {
                commands.add("rm -f /var/pari/dash/" + fileToBeDeleted.substring(fileToBeDeleted.indexOf("/") + 1));
            });
            Files.write(instructions, commands, StandardOpenOption.TRUNCATE_EXISTING);
            FileUtils.deleteDirectory(Paths.get("ServerPatch").toFile());
        } catch (Exception e) {
            logger.error("Error while modifying catalogue file", e);
        }
    }
}
