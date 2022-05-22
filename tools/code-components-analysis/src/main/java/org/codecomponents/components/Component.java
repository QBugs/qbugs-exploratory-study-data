package org.codecomponents.components;

import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;

/**
 *
 */
public class Component {

    private final String type;

    private final int[] position;

    private final String actionKey;

    /**
     *
     * @param type
     * @param position
     * @param actionKey
     */
    public Component(final String type, final int[] position, final String actionKey) {
        this.type = type;
        this.position = position;
        this.actionKey = actionKey;
    }

    /**
     *
     * @return
     */
    public String toCSVString() {
        final StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append(actionKey);
        stringBuilder.append("," + this.position[0]);
        stringBuilder.append("," + this.type);
        return stringBuilder.toString();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public int hashCode() {
        final HashCodeBuilder builder = new HashCodeBuilder();
        builder.append(this.type);
        builder.append(this.position);
        builder.append(this.actionKey); // TODO same type on the same position might be 'add' and 'move' at the same time
        return builder.toHashCode();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (!(obj instanceof Component)) {
            return false;
        }

        Component component = (Component) obj;

        final EqualsBuilder builder = new EqualsBuilder();
        builder.append(this.type, component.type);
        builder.append(this.position, component.position);
        builder.append(this.actionKey, component.actionKey);
        return builder.isEquals();
    }
}
