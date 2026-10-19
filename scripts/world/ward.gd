## WardBarrier — belief as physics. A wall held up by nothing you can kill,
## only by things that can stop believing. Belief is computed live from the
## chanters; the ward admits the bearer of the Pale Saint relic or one who has
## joined the ritual; it collapses when belief runs out.
class_name WardBarrier
extends EntityNode

# WB-24 THE CURTAIN'S LAW: an 18px stack of rungs reads as brass furniture —
# a barrier reads as a FIELD. The shimmer carries soft wings past its core
# (a ~40px curtain you cannot slip past) and its crown breathes brighter.
const CURTAIN_WING := 20.0       # the field's half-width (the old 9px pole)
const CURTAIN_WING_GAIN := 0.45  # the soft flanks' voice against the core
const CURTAIN_CROWN_T := 0.24    # the keystone band (top quarter of the field)

static func curtain_crown_gain(t: float, breath: float) -> float:
        ## pure: the crown band's gain at height-fraction t — the keystone
        ## breathes a step brighter than the field below it (a sealed gate
        ## reads by its crown the way a person reads by top-light)
        return 1.25 + 0.35 * breath if t < CURTAIN_CROWN_T else 1.0

var chanters: Array = []          # live Believer nodes feeding it
var passable := false
var broken := false
var _body: StaticBody2D
var _body_shape: CollisionShape2D

func setup_ward(p_instance: String, height: float) -> void:
        setup("WARD_BARRIER", p_instance, "ward")
        extra["height"] = height
        extra["anchor_y"] = height * 0.5
        extra["br_w"] = 40.0
        extra["br_h"] = height + 8.0

func _ready() -> void:
        super()
        _body = StaticBody2D.new()
        _body.collision_layer = E0.L_WORLD
        _body.collision_mask = 0
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(18.0, float(extra["height"]))
        shape.shape = rect
        shape.position = Vector2(0, -float(extra["height"]) * 0.5)
        _body.add_child(shape)
        _body_shape = shape
        add_child(_body)
        prompt = "THE WARD"

func belief_now() -> float:
        ## 12 hands hold it up: each living chanter sustains 25 belief. Dead or
        ## ABANDONED chanters sustain nothing. The relic bearer joins the count.
        var live_count := 0
        for c in chanters:
                if is_instance_valid(c) and not c.is_dead() and c.is_chanting():
                        live_count += 1
        var relic_bonus := 25.0 if GameState.has_flag(GameState.F_RELIQ_CARRIED) else 0.0
        return clampf(live_count * 25.0 + relic_bonus, 0.0, 100.0)

func chanter_count() -> int:
        var n := 0
        for c in chanters:
                if is_instance_valid(c) and not c.is_dead() and c.is_chanting():
                        n += 1
        return n

func update_state() -> void:
        # Data mirrors reality — the readout is never fake.
        data.properties["belief"]["value"] = int(belief_now())
        data.properties["held_by"]["value"] = maxi(chanter_count() * 4, 0)
        if broken:
                return
        var relic := GameState.has_flag(GameState.F_RELIQ_CARRIED)
        var joined := GameState.has_flag(GameState.F_JOINED_RITUAL)
        # WB-24: the ward's admission is LIVE physics too — computed fresh
        # each frame like the belief itself (the relic OPENS the ward while
        # it is carried; the wall re-seals the moment the bearer is not one)
        passable = relic or joined
        if belief_now() <= 0.0:
                _collapse()
        _body_shape.set_deferred("disabled", passable or broken)

func _collapse() -> void:
        if broken:
                return
        broken = true
        passable = true
        GameState.set_flag(GameState.F_WARD_BROKEN)
        data.set_state("BROKEN")
        AudioManager.play_sfx("sfx_barrier_break", -2.0)
        FX.shake(7.0, 0.5)
        FX.tear_pulse(0.7)

func interact(game) -> void:
        if broken:
                game.system_message("THE WARD IS SPENT. THE AIR STILL REMEMBERS BEING HELD.")
                return
        if passable:
                game.system_message("THE WARD READS YOU AND WITHDRAWS — A SUPPLICANT IS NOT AN INTRUDER.")
                return
        game.system_message("WARD INTEGRITY %d%% — HELD BY %d CHANTERS. IT ADMITS THE BEARER OF THE RELIC." % [int(belief_now()), chanter_count()])

func _process(delta: float) -> void:
        anim_t += delta
        update_state()
        queue_redraw()

func _draw() -> void:
        if broken:
                # WB-24 THE SPENT CURTAIN STAYS READABLE: the audit of the
                # broken state found NO barrier presence at all ("no barrier,
                # force field, or curtain of light") — the room's namesake
                # object vanished exactly when it died. The residue keeps
                # where belief used to stand: more scratches, wider, deeper —
                # the air still remembers being held (the system's own words)
                for i in 7:
                        var rx := -14.0 + i * 4.6
                        draw_line(Vector2(rx, -float(extra["height"])), Vector2(rx + 3.0, -6.0),
                                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.055 + 0.035 * sin(anim_t * 0.7 + i * 1.9)), 1.0)
                # a breath of spent gold still pooled at the keystone line
                draw_line(Vector2(-16.0, -float(extra["height"]) * 0.92), Vector2(16.0, -float(extra["height"]) * 0.92),
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.05 + 0.03 * sin(anim_t * 0.9)), 2.0)
                return
        var b := belief_now() / 100.0
        var h := float(extra["height"])
        # WB-24 THE CURTAIN, NOT THE CANDLESTICK: an 18px stack of rungs
        # reads as brass furniture; a barrier reads as a FIELD. Each shimmer
        # line now carries soft wings past its core (a ~40px curtain of
        # belief you cannot slip past), and the crown of the field breathes
        # a step brighter — the keystone read of a sealed gate.
        for i in 14:
                var t := float(i) / 13.0
                var y := -h * t - 3.0
                var sway := sin(anim_t * 2.2 + t * 9.0) * 3.0
                var alpha := (0.10 + 0.16 * b) * (0.7 + 0.3 * sin(anim_t * 3.0 + t * 7.0))
                var crown := curtain_crown_gain(t, sin(anim_t * 1.6))
                var lw := 2.6 if t < CURTAIN_CROWN_T else 2.0
                draw_line(Vector2(-10.0 + sway, y), Vector2(10.0 + sway, y),
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, alpha * crown), lw)
                draw_line(Vector2(-CURTAIN_WING + sway * 0.8, y), Vector2(-10.0 + sway, y),
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, alpha * CURTAIN_WING_GAIN * crown), 1.4)
                draw_line(Vector2(10.0 + sway, y), Vector2(CURTAIN_WING + sway * 0.8, y),
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, alpha * CURTAIN_WING_GAIN * crown), 1.4)
        # rune column
        for i in int(maxi(3, int(h / 40.0))):
                var ry := -20.0 - i * 40.0
                var pulse := 0.35 + 0.3 * sin(anim_t * 2.0 + i)
                draw_rect(Rect2(-3.0 + sin(anim_t + i) * 2.0, ry, 6.0, 6.0),
                        Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, pulse * b))
        if passable:
                # it parts for you: an opening outline
                var gap_h := 70.0
                draw_rect(Rect2(-11.0, -gap_h - 10.0, 4.0, gap_h), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4))
                draw_rect(Rect2(7.0, -gap_h - 10.0, 4.0, gap_h), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4))
