class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;
	public var destroyed(default,null) = false;
	public var ftime(get,never) : Float; inline function get_ftime() return game.ftime;
	public var tmod(get,never) : Float; inline function get_tmod() return Game.ME.tmod;
	public var hero(get,never) : en.Hero; inline function get_hero() return Game.ME.hero;

	public var cd : dn.Cooldown;

	public var uid : Int;
    public var cx = 0;
    public var cy = 0;
    public var xr = 0.5;
    public var yr = 0.5;
    public var zr = 0.;

    public var dx = 0.;
    public var dy = 0.;
    public var dz = 0.;
    public var bdx = 0.;
    public var bdy = 0.;
	public var dxTotal(get,never) : Float; inline function get_dxTotal() return dx+bdx;
	public var dyTotal(get,never) : Float; inline function get_dyTotal() return dy+bdy;
	public var frict = 0.82;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;
	public var hei : Float = Const.GRID;
	public var radius = Const.GRID*0.5;

	public var dir(default,set) = 1;
	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;

    public var spr : HSprite;
    public var shadow : Null<HSprite>;
	var debugLabel : Null<h2d.Text>;

	public var footX(get,never) : Float; inline function get_footX() return (cx+xr)*Const.GRID;
	public var footY(get,never) : Float; inline function get_footY() return (cy+yr)*Const.GRID;
	public var headX(get,never) : Float; inline function get_headX() return footX;
	public var headY(get,never) : Float; inline function get_headY() return footY-hei;
	public var centerX(get,never) : Float; inline function get_centerX() return footX;
	public var centerY(get,never) : Float; inline function get_centerY() return footY-hei*0.5;

    public function new(x:Int, y:Int) {
        uid = Const.NEXT_UNIQ;
        ALL.push(this);

		cd = new dn.Cooldown(Const.FPS);
        setPosCase(x,y);

        spr = new HSprite(Assets.tiles);
        Game.ME.scroller.add(spr, Const.DP_MAIN);
		spr.setCenterRatio(0.5,1);
		enableShadow();
    }

	public function disableShadow() {
		if( shadow!=null ) {
			shadow.remove();
			shadow = null;
		}
	}

	public function enableShadow() {
		disableShadow();
		shadow = new HSprite(spr.lib);
		game.scroller.add(shadow, Const.DP_BG);
		shadow.setCenterRatio(0.5,1);
		shadow.color.r = 0;
		shadow.color.g = 0;
		shadow.color.b = 0;
		shadow.alpha = 0.6;
	}

	public function zOver() {
		game.scroller.over(spr);
	}

	inline function set_dir(v) {
		return dir = v>0 ? 1 : v<0 ? -1 : dir;
	}

	public inline function isAlive() {
		return !destroyed;
	}

	public function kill(by:Null<Entity>) {
		destroy();
	}

	public function setPosCase(x:Int, y:Int, ?xr=0.5, ?yr=0.5) {
		cx = x;
		cy = y;
		this.xr = xr;
		this.yr = yr;
	}

	public function setPosPixel(x:Float, y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
	}

	public function bump(x:Float,y:Float,z:Float) {
		bdx+=x;
		bdy+=y;
		dz+=z;
	}

	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public function is<T:Entity>(c:Class<T>) return Std.is(this, c);
	public function as<T:Entity>(c:Class<T>) : T return Std.instance(this, c);

	public inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	public inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	public inline function pretty(v,?p=1) return M.pretty(v,p);

	public inline function sightCheckEnt(e:Entity) {
		return sightCheckCase(e.cx,e.cy);
	}

	public inline function sightCheckCase(tcx:Int, tcy:Int) {
		return dn.Bresenham.checkThinLine(cx,cy,tcx,tcy, function(x,y) return !level.hasCollision(x,y));
	}

	public inline function dirTo(e:Entity) return e.centerX<centerX ? -1 : 1;
	public inline function angTo(e:Entity) return Math.atan2(e.footY-footY, e.footX-footX);

	public inline function distCase(e:Entity) {
		return M.dist(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
	}

	public inline function distPx(e:Entity) {
		return M.dist(footX, footY, e.footX, e.footY);
	}

	public inline function distCaseFree(tcx:Int, tcy:Int, ?txr=0.5, ?tyr=0.5) {
		return M.dist(cx+xr, cy+yr, tcx+txr, tcy+tyr);
	}

	public inline function distPxFree(x:Float, y:Float) {
		return M.dist(footX, footY, x, y);
	}

	public function makePoint() return new CPoint(cx,cy, xr,yr);

    public inline function destroy() {
        if( !destroyed ) {
            destroyed = true;
            GC.push(this);
        }
    }

    public function dispose() {
        ALL.remove(this);

		disableShadow();

		spr.remove();
		spr = null;

		if( debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}

		cd.destroy();
		cd = null;
    }

	public inline function debugFloat(v:Float, ?p=1, ?str="") {
		debug(pretty(v,p)+str);
	}
	public inline function debug(?v:Dynamic) {
		#if debug
		if( v==null && debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}
		if( v!=null ) {
			if( debugLabel==null )
				debugLabel = new h2d.Text(Assets.fontTiny, Game.ME.scroller);
			debugLabel.text = Std.string(v);
		}
		#end
	}

	public function unlock() cd.unset("lock");
	public function lockS(sec:Float) cd.setS("lock", sec, false);
	public function getLockS() return cd.getS("lock");
	public function isLocked() return cd.has("lock");

    public function preUpdate() {
		cd.update(tmod);
    }

    public function postUpdate() {
        spr.x = (cx+xr)*Const.GRID;
        spr.y = (cy+yr-zr)*Const.GRID;
        spr.scaleX = dir*sprScaleX;
        spr.scaleY = sprScaleY;

		if( shadow!=null ) {
			shadow.set(spr.lib, spr.groupName, spr.frame);
			shadow.x = footX;
			shadow.y = footY-2 + zr*Const.GRID*0.3;
			shadow.scaleY = -0.4-0.3*zr;
		}

		if( debugLabel!=null ) {
			debugLabel.x = Std.int(footX - debugLabel.textWidth*0.5);
			debugLabel.y = Std.int(footY+1);
		}
    }

	function onZLand() {}


    public function update() {
		var wallSlide = 0.005;
		var wallSlideTolerance = 0.015;

		// X
		var steps = M.ceil( M.fabs(dxTotal*tmod) );
		var step = dxTotal*tmod / steps;
		while( steps>0 ) {
			xr+=step;
			if( level.hasCollision(cx+1, cy) && xr>0.8 ) {
				xr = 0.8;
				if( yr<0.6 && !level.hasCollision(cx+1,cy-1) && dyTotal<=wallSlideTolerance ) dy-=wallSlide*tmod;
				if( yr>0.6 && !level.hasCollision(cx+1,cy+1) && dyTotal>=-wallSlideTolerance ) dy+=wallSlide*tmod;

			}
			if( level.hasCollision(cx-1, cy) && xr<0.2 ) {
				xr = 0.2;
				if( yr<0.6 && !level.hasCollision(cx-1,cy-1) && dyTotal<=wallSlideTolerance ) dy-=wallSlide*tmod;
				if( yr>0.6 && !level.hasCollision(cx-1,cy+1) && dyTotal>=-wallSlideTolerance ) dy+=wallSlide*tmod;
			}
			while( xr>1 ) { xr--; cx++; }
			while( xr<0 ) { xr++; cx--; }
			steps--;
		}
		dx*=Math.pow(frict,tmod);
		bdx*=Math.pow(bumpFrict,tmod);
		if( M.fabs(dx)<=0.0005*tmod ) dx = 0;
		if( M.fabs(bdx)<=0.0005*tmod ) bdx = 0;

		// Y
		var steps = M.ceil( M.fabs(dyTotal*tmod) );
		var step = dyTotal*tmod / steps;
		while( steps>0 ) {
			yr+=step;
			if( level.hasCollision(cx, cy+1) && yr>0.9 ) {
				yr = 0.9;
				if( xr<0.5 && !level.hasCollision(cx-1,cy+1) && dxTotal<=wallSlideTolerance ) dx-=wallSlide*tmod;
				if( xr>0.5 && !level.hasCollision(cx+1,cy+1) && dxTotal>=-wallSlideTolerance ) dx+=wallSlide*tmod;
			}
			if( level.hasCollision(cx, cy-1) && yr<0.5 ) {
				yr = 0.5;
				if( xr<0.5 && !level.hasCollision(cx-1,cy-1) && dxTotal<=wallSlideTolerance ) dx-=wallSlide*tmod;
				if( xr>0.5 && !level.hasCollision(cx+1,cy-1) && dxTotal>=-wallSlideTolerance ) dx+=wallSlide*tmod;
			}
			while( yr>1 ) { yr--; cy++; }
			while( yr<0 ) { yr++; cy--; }
			steps--;
		}
		dy*=Math.pow(frict,tmod);
		bdy*=Math.pow(bumpFrict,tmod);
		if( M.fabs(dy)<=0.0005*tmod ) dy = 0;
		if( M.fabs(bdy)<=0.0005*tmod ) bdy = 0;

		// Z
		zr+=dz*tmod;
		if( zr>0 )
			dz-=gravity*tmod;
		if( zr<0 ) {
			zr = 0;
			dz = -dz*0.4;
			if( M.fabs(dz)<=0.02 )
				dz = 0;
			onZLand();
		}
		if( M.fabs(dz)<=0.0005*tmod ) dz = 0;
    }
}