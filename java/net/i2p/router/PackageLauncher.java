package net.i2p.router;

import net.i2p.util.SystemVersion;

import java.io.*;
import java.nio.file.*;

public class PackageLauncher {
    public static void main(String[]args) throws Exception {
        //if (!(SystemVersion.isWindows() || SystemVersion.isMac())) {
        //    System.err.println("This launcher will work only on Windows or Mac or Linux");
        //    System.exit(1);
        //}

        // 1. Select home directory
        File home = selectHome();
        if (!home.exists())
            home.mkdirs();
        else if (!home.isDirectory()) {
            System.err.println(home + " exists but is not a directory.  Please get it out of the way");
            System.exit(1);
        }

        // 2. Deploy resources
        var resourcesList = PackageLauncher.class.getClassLoader().getResourceAsStream("resources.csv");
        var reader = new BufferedReader(new InputStreamReader(resourcesList));

        String line;
        while((line = reader.readLine()) != null) {
            deployResource(home, line);
        }

        // 3. Set up environment vars
        System.setProperty("i2p.dir.base", home.getAbsolutePath());
        System.setProperty("i2p.dir.config", home.getAbsolutePath());
        System.setProperty("geoip.dir", home.getAbsolutePath() + File.separator + "geoip");
            // hmm what else?

        // 4. Launch router
        RouterLaunch.main(args);
    }


    private static File selectHome() throws Exception {
        File home = new File(System.getProperty("user.home"));
        File i2p;
        if (SystemVersion.isMac()) {
            File library = new File(home, "Library");
            File appSupport = new File(library, "Application Support");
            i2p = new File(appSupport, "I2P");
        } else if (SystemVersion.isWindows()) {
            File appData = new File(home, "AppData");
            File local = new File(appData, "Local");
            i2p = new File(local, "I2P");
        } else {
            // All other platforms
            // TODO: Maybe. Determine if it's a service and return a different home.
            i2p = new File(home, "I2P");
        }
        return i2p.getAbsoluteFile();
    }

    private static void deployResource(File home, String description) throws Exception {
        String []split = description.split(",");
        String url = split[0];
        String target = split[1];
        boolean overwrite = Boolean.parseBoolean(split[2]);

        var resource = PackageLauncher.class.getClassLoader().getResourceAsStream(url);

        File targetFile = home;
        for (String element : target.split("/")) {
            targetFile = new File(targetFile, element);
        }

        File targetDir = targetFile.getParentFile();
        if (!targetDir.exists())
            targetDir.mkdirs();
        else if (!targetDir.isDirectory())
            throw new Exception(targetDir + " exists but not a directory.  Please get it out of the way");

        if (!targetFile.exists() || overwrite)
            System.out.println(targetFile.toPath());
            Files.copy(resource, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
    }
}


