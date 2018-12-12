public abstract static class EmpathyTreePattern extends NeoPattern {
  public final EmpathyTree tree;
  public EmpathyTreePattern(LX lx) {
    super(lx, "tree");
    tree = (EmpathyTree)getObject("tree");
  }
}

@LXCategory("EmpathyTree")
public static class EmpathyTreeGradient extends NeoGradientPattern {
  GradientPattern gradient;
  public EmpathyTreeGradient(LX lx) {
    super(lx, "tree");
  }
}

@LXCategory("EmpathyTree Form")
public static class EmpathyTreeSparklesPattern extends SparklesPattern {
  GradientPattern gradient;
  public EmpathyTreeSparklesPattern(LX lx) {
    super(lx, "tree");
  }
}

@LXCategory("EmpathyTree Form")
public static class EmpathyTreeTestPattern extends EmpathyTreePattern {
  public enum Mode {
    Loop,
    Pair
  };
  public final EnumParameter<Mode> mode = new EnumParameter<Mode>("Mode", Mode.Loop);
  public final DiscreteParameter loopIdx = new DiscreteParameter("Loop", tree.LOOPS);
  public final DiscreteParameter pairIdx = new DiscreteParameter("Pair", tree.STEP);
  public final BooleanParameter left = new BooleanParameter("Left", true);
  public final BooleanParameter right = new BooleanParameter("Right", true);

  public EmpathyTreeTestPattern(LX lx) {
    super(lx);
    addParameter("mode", this.mode);
    addParameter("loop", this.loopIdx);
    addParameter("pair", this.pairIdx);
    addParameter("left", this.left);
    addParameter("right", this.right);
  }

  public void run(double deltaMs) {
    Mode mode = this.mode.getEnum();
    int loopIdx = this.loopIdx.getValuei();
    int pairIdx = loopIdx + this.pairIdx.getValuei() * tree.STEP;
    final int clOn = 0xFFFFFFFF;
    final int clOff = 0xFF000000;
    int c = clOff;
    for (EmpathyTree.Loop l : tree.loops) {
      for (EmpathyTree.BeamPair p : l.pairs) {
        if (mode == Mode.Loop) {
          c = (l.loopIdx == loopIdx) ? clOn : clOff;
        }
        else if (mode == Mode.Pair) {
          c = (l.loopIdx == loopIdx && p.pairIdx == pairIdx) ? clOn : clOff;
        }
        for (int i = 0; i < p.left.size; i++) {
          colors[p.left.points[i].index] = this.left.isOn() ? c : clOff;
          colors[p.right.points[i].index] = this.right.isOn() ? c : clOff;
        }
      }
    }
  }
}

@LXCategory("EmpathyTree Form")
public static class LoopIteratorPattern extends EmpathyTreePattern {
  public final CompoundParameter pos = new CompoundParameter("Pos", 0, 0, 1)
    .setDescription("Position of the center of the plane");

  public final CompoundParameter wth = new CompoundParameter("Width", .4, 0, 1)
    .setDescription("Thickness");
 
  private final int steps = EmpathyTree.LEDS_PER_BEAM;
  public LoopIteratorPattern(LX lx) {
    super(lx);
    addParameter("pos", this.pos);
    addParameter("width", this.wth);
  }

  public float prevPos;
  public boolean direction = false;
  @Override
  public void run(double deltaMs) {
    float pos = this.pos.getValuef();
    float falloff = 100 / (this.wth.getValuef() * (1 + abs(pos - prevPos)));
    if (direction && prevPos < pos) {
      direction = false;
    }
    if (!direction && prevPos > pos) {
      direction = true;
    }
    prevPos = pos;
    
    pos = 1.5*pos-0.25;
    for (EmpathyTree.Loop l : tree.loops) {
      for (EmpathyTree.BeamPair bp : l.pairs) {
        EmpathyTree.Beam bOn, bOff;
        if (direction) {
            bOn = bp.left;
            bOff = bp.right;
          } else {
            bOn = bp.right;
            bOff = bp.left;
          }

        for (int i = 0; i < bOn.size; i++) {
          LXPoint p = bOn.points[i];
          float n = p.zn;
          colors[p.index] = LXColor.gray(max(0, 100 - falloff*abs(n - pos)));
        }

        for (int i = 0; i < bOff.size; i++) {
          colors[bOff.points[i].index] = 0xFF000000;
        }
      }
    }
  }
}

@LXCategory("EmpathyTree Form")
public static class SpiralPattern extends EmpathyTreePattern {
  public final CompoundParameter speed = new CompoundParameter("Speed", 10, 1, 100)
    .setDescription("Speed");

  public final CompoundParameter wth = new CompoundParameter("Width", .4, 0, 1)
    .setDescription("Thickness");

  public final CompoundParameter offset = new CompoundParameter("Offset", 0, -1, 1)
    .setDescription("Offset");

  public final EnumParameter<EmpathyTree.Beam.Orientation> direction = 
    new EnumParameter<EmpathyTree.Beam.Orientation>("Direction", EmpathyTree.Beam.Orientation.LEFT)
    .setDescription("Direction");

  private final int steps = EmpathyTree.LEDS_PER_BEAM;
  public SpiralPattern(LX lx) {
    super(lx);
    addParameter("speed", this.speed);
    addParameter("width", this.wth);
    addParameter("offset", this.offset);
    addParameter("direction", this.direction);
  }

  private final LXModulator pos = startModulator(new SawLFO(0, 1, new FunctionalParameter() {
    @Override
    public double getValue() {
      return (10000 / speed.getValue());
    }
  }));
  @Override
    public void run(double deltaMs) {
      float pos = this.pos.getValuef();
      float offset = this.offset.getValuef();
      float falloff = 100 / this.wth.getValuef();

      for (EmpathyTree.Loop l : tree.loops) {
        for (EmpathyTree.BeamPair bp : l.pairs) {
          EmpathyTree.Beam bOn, bOff;
          switch (this.direction.getEnum()) {
            case LEFT:
              bOn = bp.left;
              bOff = bp.right;
              break;
            default:
              bOn = bp.right;
              bOff = bp.left;
              break;
          }

          float posOff = modulo(2*pos + (EmpathyTree.FEET_NUM-bp.pairIdx)*offset, 2.0f)-0.5;
          for (int i = 0; i < bOn.size; i++) {
            LXPoint p = bOn.points[i];
            float n = p.zn;
            colors[p.index] = LXColor.gray(max(0, 100 - falloff*abs(n - posOff)));
          }

          for (int i = 0; i < bOff.size; i++) {
            colors[bOff.points[i].index] = 0xFF000000;
          }
        }
      }
    }
}
