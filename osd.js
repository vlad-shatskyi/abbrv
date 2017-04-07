Layout = imports.ui.layout;

HIDE_TIMEOUT = 5000;
FADE_TIME = 0.1;

iteration = (typeof iteration === 'undefined') ? 0 : (iteration + 1);

OsdWindow = new Lang.Class({
    Name: 'OsdWindow' + iteration,

    _init: function(monitorIndex) {
        this.actor = new imports.gi.St.Widget({ x_expand: true,
            y_expand: true,
            x_align: imports.gi.Clutter.ActorAlign.CENTER,
            y_align: imports.gi.Clutter.ActorAlign.CENTER });

        this._monitorIndex = monitorIndex;
        let constraint = new Layout.MonitorConstraint({ index: monitorIndex });
        this.actor.add_constraint(constraint);

        this._box = new imports.gi.St.BoxLayout({ style_class: 'osd-window',
            vertical: true });
        this.actor.add_actor(this._box);

        this._label = new imports.gi.St.Label();
        this._box.add(this._label);

        this._hideTimeoutId = 0;
        this._reset();

        Main.layoutManager.connect('monitors-changed',
            Lang.bind(this, this._relayout));
        let themeContext = imports.gi.St.ThemeContext.get_for_stage(global.stage);
        themeContext.connect('notify::scale-factor',
            Lang.bind(this, this._relayout));
        this._relayout();
        Main.uiGroup.add_child(this.actor);
    },

    setLabel: function(label) {
        this._label.visible = (label != undefined);
        if (label)
            this._label.text = label;
    },

    show: function() {
        if (!this.actor.visible) {
            Meta.disable_unredirect_for_screen(global.screen);
            this.actor.show();
            this.actor.opacity = 0;
            this.actor.get_parent().set_child_above_sibling(this.actor, null);

            imports.ui.tweener.addTween(this.actor,
                { opacity: 255,
                    time: FADE_TIME,
                    transition: 'easeOutQuad' });
        }

        if (this._hideTimeoutId)
            imports.mainloop.source_remove(this._hideTimeoutId);
        this._hideTimeoutId = imports.mainloop.timeout_add(HIDE_TIMEOUT,
            Lang.bind(this, this._hide));
        GLib.Source.set_name_by_id(this._hideTimeoutId, '[gnome-shell] this._hide');
    },

    cancel: function() {
        if (!this._hideTimeoutId)
            return;

        imports.mainloop.source_remove(this._hideTimeoutId);
        this._hide();
    },

    _hide: function() {
        this._hideTimeoutId = 0;
        imports.ui.tweener.addTween(this.actor,
            { opacity: 0,
                time: FADE_TIME,
                transition: 'easeOutQuad',
                onComplete: Lang.bind(this, function() {
                    this._reset();
                    Meta.enable_unredirect_for_screen(global.screen);
                })
            });
        return GLib.SOURCE_REMOVE;
    },

    _reset: function() {
        this.actor.hide();
        this.setLabel(null);
    },

    _relayout: function() {
        let monitor = Main.layoutManager.monitors[this._monitorIndex];
        if (!monitor)
            return;

        this._box.translation_y = monitor.height / 4;
    }
});

osdWindow = new OsdWindow(0);
osdWindow.setLabel('label that is so long');
osdWindow.show();
