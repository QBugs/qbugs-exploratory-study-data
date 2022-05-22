package org.codecomponents.commands;

import org.codecomponents.command.Command;
import org.codecomponents.components.Component;
import org.codecomponents.util.GumTreeDiffWrapper;
import org.kohsuke.args4j.Option;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.io.PrintWriter;

/**
 * The <code>listBuggyCodeComponents</code> command.
 */
public class ListBuggyCodeComponents extends Command {

    @Option(name = "--buggyFile", usage = "path to the buggy .py file", metaVar = "<path>", required = true)
    private File buggyFile;

    @Option(name = "--fixedFile", usage = "path to the fixed .py file", metaVar = "<path>", required = true)
    private File fixedFile;

    @Option(name = "--outputFile", usage = "file to which data will be written", metaVar = "<file>", required = false)
    private File outputFile = new File("buggy-code-components.csv");

    /**
     * {@inheritDoc}
     */
    @Override
    public String description() {
        return "List the set of buggy components in a diff.";
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String name() {
        return "listBuggyCodeComponents";
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public int execute(final PrintStream out, final PrintStream err) throws Exception {
        out.println("* " + this.description());

        // Sanity checks
        if (!this.buggyFile.exists()) {
            throw new FileNotFoundException(this.buggyFile.getAbsolutePath() + " does not exist!");
        }
        if (!this.fixedFile.exists()) {
            throw new FileNotFoundException(this.fixedFile.getAbsolutePath() + " does not exist!");
        }

        final PrintWriter outputWriter = new PrintWriter(this.outputFile, "UTF-8");
        final String header = "edit_type,line_number,code_component";
        outputWriter.println(header);

        for (Component component : GumTreeDiffWrapper.getInstance(this.buggyFile, this.fixedFile).findBuggyComponents()) {
            outputWriter.println(component.toCSVString());
        }

        outputWriter.flush();
        outputWriter.close();

        out.println("* Done!");
        return 0;
    }
}
