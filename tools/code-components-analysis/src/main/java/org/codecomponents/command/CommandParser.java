package org.codecomponents.command;

import org.kohsuke.args4j.CmdLineParser;

/**
 * Parser which remembers the parsed command to have additional context information to produce help output.
 */
public class CommandParser extends CmdLineParser {

    private final Command command;

    public CommandParser(final Command command) {
        super(command);
        this.command = command;
    }

    public Command getCommand() {
        return command;
    }
}
