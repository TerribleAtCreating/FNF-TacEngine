package editors;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import Character;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;

//idfk how to make states ok
import Achievements.AttachedAchievement;
import Achievements.CustomAward;
import flash.net.FileFilter;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class AwardEditorState extends MusicBeatState
{
	var exampleAward:Array<Dynamic> = ["Name", "Description", "exampleAward", false];
    var options:Array<Dynamic> = [];
    private var grpOptions:FlxTypedGroup<Alphabet>;
    private var descText:FlxText;
	var icon:AttachedAchievement;
    
	private var achievementArray:Array<AttachedAchievement> = [];
	private var achievementIndex:Array<Int> = [];
    private var curSelected:Int = 0;

    var optionText:Alphabet = null;
    var UI_box:FlxUITabMenu;
    var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var awardFile:CustomAward = null;
	static var awardFileName:String = 'exampleAward';

    public function new()
    {
        super();
    }

    override function create()
    {
		awardFile = Achievements.createAwardFile();
        #if desktop
		DiscordClient.changePresence("Achievements Editor", null);
		#end

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = ClientPrefs.globalAntialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		options.push(exampleAward);

		for (i in 0...options.length) {
			optionText = new Alphabet(0, (100 * i) + 210, awardFile.name, false, false);
			optionText.isMenuItem = true;
			optionText.x += 280;
			optionText.xAdd = 200;
			optionText.targetY = i;
			grpOptions.add(optionText);

			icon = new AttachedAchievement(optionText.x - 105, optionText.y, exampleAward[2], true);
			icon.sprTracker = optionText;
			achievementArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		changeSelection();
        addEditorBox();
		reloadAllStuff();

		super.create();
		FlxG.mouse.visible = true;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
		if(loadedAward != null) {
			awardFile = loadedAward;
			loadedAward = null;

			reloadAllStuff();
		}
        var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;
				break;
			}
		}
		if (FlxG.keys.justPressed.ESCAPE && !blockInput) {
			FlxG.mouse.visible = false;
            MusicBeatState.switchState(new editors.MasterEditorMenu());
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
    }

    function addEditorBox() {
		var tabs = [
			{name: 'Award', label: 'Award'}
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 375);
		UI_box.x = FlxG.width - UI_box.width;
		UI_box.y = FlxG.height - UI_box.height;
		UI_box.scrollFactor.set();
		addOtherBoxStuff();
		UI_box.selected_tab_id = 'Award';
		add(UI_box);
	}

	var nameInputText:FlxUIInputText;
	var descInputText:FlxUIInputText;
	var fileNameInputText:FlxUIInputText;
	var hiddenCheckBox:FlxUICheckBox;
	function addOtherBoxStuff()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = 'Award';
        nameInputText = new FlxUIInputText(10, 30, 200, '', 8);
        descInputText = new FlxUIInputText(10, 60, 200, '', 8);
		fileNameInputText = new FlxUIInputText(10, 90, 200, '', 8);
        hiddenCheckBox = new FlxUICheckBox(10, 120, null, null, "Hide Award?", 100);
		hiddenCheckBox.callback = function()
		{
			awardFile.hidden = hiddenCheckBox.checked;
		};
        blockPressWhileTypingOn.push(nameInputText);
		blockPressWhileTypingOn.push(descInputText);
		blockPressWhileTypingOn.push(fileNameInputText);
		var saveAwardButton:FlxButton = new FlxButton(10, 150, "Save Award", function() {
			saveAward(awardFile);
		});
		var loadAwardButton:FlxButton = new FlxButton(10, 180, "Load Award", function() {
			loadAward();
		});

        tab_group.add(new FlxText(nameInputText.x, nameInputText.y - 18, 0, 'Name:'));
        tab_group.add(new FlxText(descInputText.x, descInputText.y - 18, 0, 'Description:'));
		tab_group.add(new FlxText(fileNameInputText.x, fileNameInputText.y - 18, 0, 'File Name:'));
        tab_group.add(nameInputText);
        tab_group.add(descInputText);
		tab_group.add(hiddenCheckBox);
		tab_group.add(fileNameInputText);
		tab_group.add(saveAwardButton);
		tab_group.add(loadAwardButton);
		UI_box.addGroup(tab_group);
	}

	function reloadAllStuff()
	{
		nameInputText.text = awardFile.name;
		descInputText.text = awardFile.description;
		fileNameInputText.text = awardFileName;
		hiddenCheckBox.checked = awardFile.hidden;
		remove(icon);
		achievementArray.remove(icon);
		icon = new AttachedAchievement(optionText.x - 105, optionText.y, awardFileName, true);
		icon.sprTracker = optionText;
		achievementArray.push(icon);
		add(icon);
		var textToType:String = nameInputText.text;
		if(textToType == null || textToType.length < 1) textToType = ' ';
		if(optionText != null) {
			optionText.changeText(textToType);
		}
	}

	private static var _file:FileReference;
	public static function saveAward(awardFile:CustomAward) {
		var data:String = Json.stringify(awardFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, awardFileName + ".json");
		}
	}

	private static function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	private static function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	public static function loadAward() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}
	
	public static var loadedAward:CustomAward = null;
	public static var loadError:Bool = false;
	private static function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				loadedAward = cast Json.parse(rawJson);
				if(loadedAward.name != null && loadedAward.description != null && (loadedAward.hidden || !loadedAward.hidden)) //Make sure it's really an award
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					loadError = false;

					awardFileName = cutName;
					_file = null;
					return;
				}
			}
		}
		loadError = true;
		loadedAward = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if (sender == nameInputText)
			{
				reloadNameText();
				awardFile.name = nameInputText.text;
			} else if (sender == descInputText)
			{
				var text:String = descInputText.text;
				if(text == null || text.length < 1) text = ' ';
				descText.text = text;
				awardFile.description = text;
			} else if (sender == fileNameInputText)
			{
				remove(icon);
				achievementArray.remove(icon);
				icon = new AttachedAchievement(optionText.x - 105, optionText.y, fileNameInputText.text, true);
				icon.sprTracker = optionText;
				achievementArray.push(icon);
				add(icon);
				awardFileName = fileNameInputText.text;
			}
		}
	}

    function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		for (i in 0...achievementArray.length) {
			achievementArray[i].alpha = 0.6;
			if(i == curSelected) {
				achievementArray[i].alpha = 1;
			}
		}
		descText.text = exampleAward[1];
	}

    function reloadNameText()
    {
		var textToType:String = nameInputText.text;
		if(textToType == null || textToType.length < 1) textToType = ' ';
		if(optionText != null) {
			optionText.changeText(textToType);
		}
    }
}