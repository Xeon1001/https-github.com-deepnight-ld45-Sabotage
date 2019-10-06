package en;

class Door extends Entity {
	public static var ALL : Array<Door> = [];

	var isOpen = false;

	public function new(x,y) {
		super(x,y);
		yr = 1;
		ALL.push(this);
		hasCollisions = false;

		spr.set(level.hasCollision(cx,cy+1) ? "doorV" : "doorH");
		if( level.hasCollision(cx,cy+1) )
			if( level.hasRoof(cx+1,cy) )
				xr = 0.8;
			else
				xr = 0.2;
		updateCollisions();
		disableShadow();
	}

	function updateCollisions() {
		if( level!=null && !level.destroyed )
			level.setCollision(cx,cy, !isOpen);
	}

	public function open() {
		isOpen = true;
		updateCollisions();
	}

	override function dispose() {
		super.dispose();
		isOpen = true;
		updateCollisions();
	}
	override function postUpdate() {
		super.postUpdate();
		if( cd.has("shake") ) {
			spr.x +=Math.cos(ftime*2) * cd.getRatio("shake")*1;
		}
	}

	override function update() {
		cancelVelocities();
		super.update();

		if( !isOpen && ( hero.at(cx,cy-1) || hero.at(cx,cy+1) || hero.at(cx-1,cy) || hero.at(cx+1,cy) ) && !cd.hasSetS("heroShake",0.4) )
			cd.setS("shake", 0.2);
	}
}