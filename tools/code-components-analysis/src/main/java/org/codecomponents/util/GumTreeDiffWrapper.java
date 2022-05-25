package org.codecomponents.util;

import com.github.gumtreediff.actions.ChawatheScriptGenerator;
import com.github.gumtreediff.actions.EditScript;
import com.github.gumtreediff.actions.EditScriptGenerator;
import com.github.gumtreediff.actions.model.Action;
import com.github.gumtreediff.actions.model.Addition;
import com.github.gumtreediff.actions.model.Delete;
import com.github.gumtreediff.actions.model.Insert;
import com.github.gumtreediff.actions.model.Move;
import com.github.gumtreediff.actions.model.Update;
import com.github.gumtreediff.client.Run;
import com.github.gumtreediff.gen.python.PythonTreeGenerator;
import com.github.gumtreediff.io.LineReader;
import com.github.gumtreediff.matchers.MappingStore;
import com.github.gumtreediff.matchers.Matcher;
import com.github.gumtreediff.matchers.Matchers;
import com.github.gumtreediff.tree.Tree;
import org.codecomponents.components.Component;

import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Utility functions/wrapper for [GumTree](https://github.com/GumTreeDiff/gumtree)
 */
public class GumTreeDiffWrapper {

    private static GumTreeDiffWrapper SINGLETON = null;

    private final LineReader lineReaderBuggyFile;

    private final Tree buggyTree;

    private final LineReader lineReaderFixedFile;

    private final Tree fixedTree;

    /**
     *
     * @param buggyFile
     * @param fixedFile
     */
    private GumTreeDiffWrapper(final File buggyFile, final File fixedFile) throws Exception {
        // Register the available parsers
        Run.initGenerators();

        final PythonTreeGenerator pythonTreeGenerator = new PythonTreeGenerator();

        this.lineReaderBuggyFile = new LineReader(new FileReader(buggyFile));
        this.buggyTree = pythonTreeGenerator.generateFrom().reader(this.lineReaderBuggyFile).getRoot();

        this.lineReaderFixedFile = new LineReader(new FileReader(fixedFile));
        this.fixedTree = pythonTreeGenerator.generateFrom().reader(this.lineReaderFixedFile).getRoot();
    }

    /**
     *
     * @return
     */
    public static GumTreeDiffWrapper getInstance() {
        assert SINGLETON != null;
        return SINGLETON;
    }

    /**
     *
     * @param buggyFile
     * @param fixedFile
     * @return
     */
    public static GumTreeDiffWrapper getInstance(final File buggyFile, final File fixedFile) throws Exception {
        if (SINGLETON == null) {
            SINGLETON = new GumTreeDiffWrapper(buggyFile, fixedFile);
        }
        return SINGLETON;
    }

    /**
     *
     * @return
     */
    public Set<Component> findBuggyComponents() {
        // Retrieve the default matcher
        final Matcher matcher = Matchers.getInstance().getMatcher();
        // Compute the mappings between the buggy and fixed tree
        final MappingStore mappings = matcher.match(this.buggyTree, this.fixedTree);
        // Instantiate the simplified Chawathe script generator
        final EditScriptGenerator editScriptGenerator = new ChawatheScriptGenerator();
        // Compute the edit script
        final EditScript actions = editScriptGenerator.computeActions(mappings);
        // Process the edit actions
        final Set<Component> buggyComponents = new LinkedHashSet<Component>();
        for (Action action : actions) {
            final Tree node = action.getNode();
            if (action instanceof Delete || action instanceof Move || action instanceof Update) {
                buggyComponents.addAll(this.findAllComponents(lineReaderBuggyFile, node, action));
            }
        }
        return buggyComponents;
    }

    /**
     *
     * @return
     */
    public Set<Component> findFixedComponents() {
        // Retrieve the default matcher
        final Matcher matcher = Matchers.getInstance().getMatcher();
        // Compute the mappings between the buggy and fixed tree
        final MappingStore mappings = matcher.match(this.buggyTree, this.fixedTree);
        // Instantiate the simplified Chawathe script generator
        final EditScriptGenerator editScriptGenerator = new ChawatheScriptGenerator();
        // Compute the edit script
        final EditScript actions = editScriptGenerator.computeActions(mappings);
        // Process the edit actions
        final Set<Component> fixedComponents = new LinkedHashSet<Component>();
        for (Action action : actions) {
            final Tree node = action.getNode();
            if (action instanceof Addition || action instanceof Move || action instanceof Update) {
                fixedComponents.addAll(this.findAllComponents(lineReaderFixedFile, node, action));
            }
        }
        return fixedComponents;
    }

    private List<Component> findAllComponents(final LineReader lineReader, final Tree node, final Action action) {
        final List<Component> components = new ArrayList<Component>();

        Component component = new Component(node.getType().name, lineReader.positionFor(node.getPos()), this.actionKey(action));
        components.add(component);

        for (final Tree child : node.getChildren()) {
            components.addAll(this.findAllComponents(lineReader, child, action));
        }

        return components;
    }

    private String actionKey(final Action action) {
        if (action instanceof Addition) {
            return "A";
        } else if (action instanceof Insert) {
            return "I";
        } else if (action instanceof Delete) {
            return "D";
        } else if (action instanceof Move) {
            return "M";
        } else if (action instanceof Update) {
            return "U";
        }
        return "UNK";
    }
}
