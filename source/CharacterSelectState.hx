package;
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

#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class CharacterSelectState extends MusicBeatState
{
    var currentChar:Int = 0;
    var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('playableCharsList'));
    override function create()
    {
        #if MODS_ALLOWED
        var directories:Array<String> = [Paths.mods('playable/'), Paths.mods(Paths.currentModDirectory + '/playable/'), Paths.getPreloadPath('playable/')];
        #else
        var directories:Array<String> = [Paths.getPreloadPath('playable/')];
        #end
        var tempMap:Map<String, Bool> = new Map<String, Bool>();

        for (i in 0...characters.length) {
            tempMap.set(characters[i], true);
        }

        #if MODS_ALLOWED
        for (i in 0...directories.length) {
            var directory:String = directories[i];
            if(FileSystem.exists(directory)) {
                for (file in FileSystem.readDirectory(directory)) {
                    var path = haxe.io.Path.join([directory, file]);
                    if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
                        var charToCheck:String = file.substr(0, file.length - 5);
                        if(!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck)) {
                            tempMap.set(charToCheck, true);
                            characters.push(charToCheck);
                        }
                    }
                }
            }
        }
    #end
    }

    override function update(elapsed)
    {
        var left = controls.UI_LEFT;
        var right = controls.UI_RIGHT;
    }
}