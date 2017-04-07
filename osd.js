Layout = imports.ui.layout;

HIDE_TIMEOUT = 500;
FADE_TIME = 0.1;
LEVEL_ANIMATION_TIME = 0.1;

iteration = (typeof iteration === 'undefined') ? 0 : (iteration + 1);

LevelBar = new Lang.Class({
    Name: 'LevelBar' + iteration,

    _init: function() {
        this._level = 0;

        this.actor = new St.Bin({ style_class: 'level',
            x_align: St.Align.START,
            y_fill: true });
        this._bar = new St.Widget({ style_class: 'level-bar' });

        this.actor.set_child(this._bar);

        this.actor.connect('notify::width', () => { this.level = this.level; });
    },

    get level() {
        return this._level;
    },

    set level(value) {
        this._level = Math.max(0, Math.min(value, 100));

        let alloc = this.actor.get_allocation_box();
        let newWidth = Math.round((alloc.x2 - alloc.x1) * this._level / 100);
        if (newWidth != this._bar.width)
            this._bar.width = newWidth;
    }
});

OsdWindowConstraint = new Lang.Class({
    Name: 'OsdWindowConstraint' + iteration,
    Extends: Clutter.Constraint,

    _init: function(props) {
        this._minSize = 0;
        this.parent(props);
    },

    set minSize(v) {
        this._minSize = v;
        if (this.actor)
            this.actor.queue_relayout();
    },
});

OsdWindow = new Lang.Class({
    Name: 'OsdWindow' + iteration,

    _init: function(monitorIndex) {
        this.actor = new St.Widget({ x_expand: true,
            y_expand: true,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER });

        this._monitorIndex = monitorIndex;
        let constraint = new Layout.MonitorConstraint({ index: monitorIndex });
        this.actor.add_constraint(constraint);

        this._boxConstraint = new OsdWindowConstraint();
        this._box = new St.BoxLayout({ style_class: 'osd-window',
            vertical: true });
        this._box.add_constraint(this._boxConstraint);
        this.actor.add_actor(this._box);

        this._icon = new St.Icon();
        this._box.add(this._icon, { expand: true });

        this._label = new St.Label();
        this._box.add(this._label);

        this._level = new LevelBar();
        this._box.add(this._level.actor);

        this._hideTimeoutId = 0;
        this._reset();

        Main.layoutManager.connect('monitors-changed',
            Lang.bind(this, this._relayout));
        let themeContext = St.ThemeContext.get_for_stage(global.stage);
        themeContext.connect('notify::scale-factor',
            Lang.bind(this, this._relayout));
        this._relayout();
        Main.uiGroup.add_child(this.actor);
    },

    setIcon: function(icon) {
        this._icon.gicon = icon;
    },

    setLabel: function(label) {
        this._label.visible = (label != undefined);
        if (label)
            this._label.text = label;
    },

    setLevel: function(level) {
        this._level.actor.visible = (level != undefined);
        if (level != undefined) {
            if (this.actor.visible)
                Tweener.addTween(this._level,
                    { level: level,
                        time: LEVEL_ANIMATION_TIME,
                        transition: 'easeOutQuad' });
            else
                this._level.level = level;
        }
    },

    show: function() {
        if (!this._icon.gicon)
            return;

        if (!this.actor.visible) {
            Meta.disable_unredirect_for_screen(global.screen);
            this.actor.show();
            this.actor.opacity = 0;
            this.actor.get_parent().set_child_above_sibling(this.actor, null);

            Tweener.addTween(this.actor,
                { opacity: 255,
                    time: FADE_TIME,
                    transition: 'easeOutQuad' });
        }

        if (this._hideTimeoutId)
            Mainloop.source_remove(this._hideTimeoutId);
        this._hideTimeoutId = Mainloop.timeout_add(HIDE_TIMEOUT,
            Lang.bind(this, this._hide));
        GLib.Source.set_name_by_id(this._hideTimeoutId, '[gnome-shell] this._hide');
    },

    cancel: function() {
        if (!this._hideTimeoutId)
            return;

        Mainloop.source_remove(this._hideTimeoutId);
        this._hide();
    },

    _hide: function() {
        this._hideTimeoutId = 0;
        Tweener.addTween(this.actor,
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
        this.setLevel(null);
    },

    _relayout: function() {
        /* assume 110x110 on a 640x480 display and scale from there */
        let monitor = Main.layoutManager.monitors[this._monitorIndex];
        if (!monitor)
            return; // we are about to be removed

        let scalew = monitor.width / 640.0;
        let scaleh = monitor.height / 480.0;
        let scale = Math.min(scalew, scaleh);
        let popupSize = 110 * Math.max(1, scale);

        let scaleFactor = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        this._icon.icon_size = popupSize / (2 * scaleFactor);
        this._box.translation_y = monitor.height / 4;
        this._boxConstraint.minSize = popupSize;
    }
});

osdWindow = new OsdWindow(0);
osdWindow.setLabel('label');
osdWindow.setIcon(Gio.Icon.new_for_string('starred'));
osdWindow.show();
