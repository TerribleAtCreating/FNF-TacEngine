import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
#end

using StringTools;

typedef CustomAward = {
	var awardName:String;
	var description:String;
	var hidden:Bool;
	//yeah its this short, so what?
}
class Achievements {
	public static var defaultAchievementsStuff:Array<Dynamic> = [ //Name, Description, Achievement save tag, Hidden achievement
		["Freaky on a Friday Night",	"Play on a Friday... Night.",						'friday_night_play',	 true],
		["She Calls Me Daddy Too",		"Beat Week 1 on Hard with no Misses.",				'week1_nomiss',			false],
		["No More Tricks",				"Beat Week 2 on Hard with no Misses.",				'week2_nomiss',			false],
		["Call Me The Hitman",			"Beat Week 3 on Hard with no Misses.",				'week3_nomiss',			false],
		["Lady Killer",					"Beat Week 4 on Hard with no Misses.",				'week4_nomiss',			false],
		["Missless Christmas",			"Beat Week 5 on Hard with no Misses.",				'week5_nomiss',			false],
		["Highscore!!",					"Beat Week 6 on Hard with no Misses.",				'week6_nomiss',			false],
		["You'll Pay For That...",		"Beat Week 7 on Hard with no Misses.",				'week7_nomiss',			 true],
		["What a Funkin' Disaster!",	"Complete a Song with a rating lower than 20%.",	'ur_bad',				false],
		["Perfectionist",				"Complete a Song with a rating of 100%.",			'ur_good',				false],
		["Roadkill Enthusiast",			"Watch the Henchmen die over 100 times.",			'roadkill_enthusiast',	false],
		["Oversinging Much...?",		"Hold down a note for 20 seconds.",					'oversinging',			false],
		["Hyperactive",					"Finish a Song without going Idle.",				'hype',					false],
		["Just the Two of Us",			"Finish a Song pressing only two keys.",			'two_keys',				false],
		["Toaster Gamer",				"Have you tried to run the game on a toaster?",		'toastie',				false],
		["Debugger",					"Beat the \"Test\" Stage from the Chart Editor.",	'debugger',				 true]
	];

	public static var achievementsStuff:Array<Dynamic> = defaultAchievementsStuff;
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static var henchmenDeath:Int = 0;
	public static function unlockAchievement(name:String):Void {
		FlxG.log.add('Completed achievement "' + name +'"');
		achievementsMap.set(name, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public function reloadAchievements()
	{
		achievementsStuff = defaultAchievementsStuff;
		#if MODS_ALLOWED
		var directories:Array<String> = [''];
		for (folder in Paths.getModDirectories())
		{
			directories.push(folder);
		}
		for (directory in directories)
		{
			var theList = mods(directory + '/achievements/awardsList.txt');
			if (directory == '')
			{
				theList = mods('achievements/awardsList.txt');
			}
			if (FileSystem.exists(theList))
			{
				var content = File.getContent(theList);
				var awards:Array<String> = content.split('\n');
				for (award in awards)
				{
					var awardDesc:String = "No description was provided.";
					var awardName:String = award;
					var isHidden:Bool = false;

					var moddyFile:String = Paths.modFolders('achievements/' + name + '.json');
					var awardJson = null;

					if(FileSystem.exists(moddyFile))
					{
						awardJson = File.getContent(moddyFile).trim();
						while (!awardJson.endsWith("}"))
						{
							awardJson = awardJson.substr(0, awardJson.length - 1);
							// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
						}

						var stuff:CustomAward = cast Json.parse(awardJson);
						if (stuff.name != null && stuff.name.length > 0)
						{
							awardName = stuff.name;
						}
						if (stuff.description != null && stuff.description.length > 0)
						{
							awardDesc = stuff.name;
						}
						if (stuff.hidden != null)
						{
							isHidden = stuff.hidden;
						}
						achievementssStuff.push([awardName, awardDesc, award, isHidden])
					}
				}
			}
		}
		#end
	}

	public static function isAchievementUnlocked(name:String) {
		if(achievementsMap.exists(name) && achievementsMap.get(name)) {
			return true;
		}
		return false;
	}

	public static function getAchievementIndex(name:String) {
		for (i in 0...achievementsStuff.length) {
			if(achievementsStuff[i][2] == name) {
				return i;
			}
		}
		return -1;
	}

	public static function loadAchievements():Void {
		if(FlxG.save.data != null) {
			if(FlxG.save.data.achievementsMap != null) {
				achievementsMap = FlxG.save.data.achievementsMap;
			}
			if(FlxG.save.data.achievementsUnlocked != null) {
				FlxG.log.add("Trying to load stuff");
				var savedStuff:Array<String> = FlxG.save.data.achievementsUnlocked;
				for (i in 0...savedStuff.length) {
					achievementsMap.set(savedStuff[i], true);
				}
			}
			if(henchmenDeath == 0 && FlxG.save.data.henchmenDeath != null) {
				henchmenDeath = FlxG.save.data.henchmenDeath;
			}
		}

		// You might be asking "Why didn't you just fucking load it directly dumbass??"
		// Well, Mr. Smartass, consider that this class was made for Mind Games Mod's demo,
		// i'm obviously going to change the "Psyche" achievement's objective so that you have to complete the entire week
		// with no misses instead of just Psychic once the full release is out. So, for not having the rest of your achievements lost on
		// the full release, we only save the achievements' tag names instead. This also makes me able to rename
		// achievements later as long as the tag names aren't changed of course.

		// Edit: Oh yeah, just thought that this also makes me able to change the achievements orders easier later if i want to.
		// So yeah, if you didn't thought about that i'm smarter than you, i think

		// buffoon
	}
}

class AttachedAchievement extends FlxSprite {
	public var sprTracker:FlxSprite;
	private var tag:String;
	public function new(x:Float = 0, y:Float = 0, name:String) {
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function changeAchievement(tag:String) {
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage() {
		if(Achievements.isAchievementUnlocked(tag)) {
			loadGraphic(Paths.image('achievementgrid'), true, 150, 150);
			animation.add('icon', [Achievements.getAchievementIndex(tag)], 0, false, false);
			animation.play('icon');
		} else {
			loadGraphic(Paths.image('lockedachievement'));
		}
		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup {
	public var onFinish:Void->Void = null;
	var alphaTween:FlxTween;
	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var iconPath = Paths.image('achievementgrid');
		var awardName = null;
		var awardDesc = null;
		if (checkModAward(name))
		{
			awardName = Achievements.achievementsStuff[id][0];
			awardDesc = Achievements.achievementsStuff[id][1];
		}
		//i think this is gonna be unneccessarily stupid
		#if MODS_ALLOWED
		if (checkModAward(name))
		{
			var modsIconPath = Paths.modFolders('achievements/' + name + '.png');
			if(FileSystem.exists(modsIconPath)) {
				iconPath = modsIconPath;
			} else {
				iconPath = Paths.image('unknownMod', 'preload');
			}
			var moddyFile:String = Paths.modFolders('achievements/' + name + '.json');
			var awardJson = null;
			if(FileSystem.exists(moddyFile))
			{
				awardJson = File.getContent(moddyFile).trim();
				while (!awardJson.endsWith("}"))
				{
					awardJson = awardJson.substr(0, awardJson.length - 1);
					// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
				}
				var stuff:CustomAward = cast Json.parse(awardJson);
				if (stuff.name != null)
				{
					awardName = stuff.name;
				} else {
					awardName = name;
				}
				if (stuff.description != null)
				{
					awardDesc = stuff.name;
				} else {
					awardDesc = "No description was provided.";
				}
			}
		}
		#end
		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(iconPath, true, 150, 150);
		achievementIcon.animation.add('icon', [id], 0, false, false);
		achievementIcon.animation.play('icon');
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.globalAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280, awardName, 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, awardDesc, 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if(camera != null) {
			cam = [camera];
		}
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {onComplete: function (twn:FlxTween) {
			alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
				startDelay: 2.5,
				onComplete: function(twn:FlxTween) {
					alphaTween = null;
					remove(this);
					if(onFinish != null) onFinish();
				}
			});
		}});
	}

	private function checkModAward(aName:String)
	{
		var isMod = false;
		#if MODS_ALLOWED
		var awardListPath = Paths.modFolders('achievements/awardsList.txt');
		if (FileSystem.exists(awardListPath))
		{
			var awards = CoolUtil.coolTextFile(awardListPath);
			if (awards.contains(aName))
			{
				isMod = true;
			}
		}
		#end
		return isMod;
	}

	override function destroy() {
		if(alphaTween != null) {
			alphaTween.cancel();
		}
		super.destroy();
	}
	
}