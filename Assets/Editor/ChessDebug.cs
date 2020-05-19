using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public class ChessDebug : EditorWindow {
    
    public Texture2D chessAtlas = null;
    public Texture2D border = null;
    public int selBoard = 0;
    public int selPiece = 0;
    public GUIContent[] chessList = null;
    public GUIContent[] pcList = null;
    public Texture2D[,] boardTex = null;
    public GUIStyle myBox = null;
    public string outString = "Hello World";

    public static Texture2D LoadPNG(string filePath, int x, int y) {
     
        Texture2D tex = null;
        byte[] fileData;
     
        if (File.Exists(filePath))     {
            fileData = File.ReadAllBytes(filePath);
            tex = new Texture2D(x, y, TextureFormat.RGBA32, false);
            tex.LoadImage(fileData); //..this will auto-resize the texture dimensions.
            
        }
        return tex;
    }

    [MenuItem("Tools/SCRN/Chess Debug")]
    static void Init()
    {
        var window = GetWindowWithRect<ChessDebug>(new Rect(0, 0, 600, 600));

        window.chessAtlas = LoadPNG("Assets/Chess/Textures/Atlas.png", 512, 512);
        window.border = LoadPNG("Assets/Chess/Textures/border-red.png", 3, 3);
        window.boardTex = new Texture2D[8, 8];
        
        List<GUIContent> cL = new List<GUIContent>();
        List<GUIContent> pL = new List<GUIContent>();
        int i = 0;
        for (; i < 64; i++) {
            cL.Add(new GUIContent("(" +  (8 - Mathf.Floor(i / 8)) +
                ", " + (i % 8 + 1) + ") "));
        }
        for (i = 0; i < 7; i++) {
            pL.Add(new GUIContent("White"));
            pL.Add(new GUIContent("Black"));
        }
        window.chessList = (GUIContent[])cL.ToArray();
        window.pcList = (GUIContent[])pL.ToArray();
        window.Show();
    }

    void OnGUI()
    {

        GUIStyle myStyle = new GUIStyle(GUI.skin.box);
        myStyle.margin = new RectOffset(0, 0, 0, 0);
        myStyle.border = new RectOffset(1, 1, 1, 1);
        myStyle.active.background = border;
        myStyle.onNormal.background = border;
        myBox = myStyle;

        EditorGUILayout.BeginHorizontal();
        selBoard = GUILayout.SelectionGrid(selBoard, chessList, 8,
            myBox,
            GUILayout.Width(500), GUILayout.Height(500),
            GUILayout.MinHeight(0), GUILayout.MinWidth(0));

        //---- Right Side ----//
        EditorGUILayout.BeginVertical();
        GUILayout.Label("Chess Atlas", EditorStyles.boldLabel);
        chessAtlas = (Texture2D) EditorGUILayout.ObjectField("", chessAtlas,
            typeof(Texture2D), false, GUILayout.Width(65));

        //---- Pieces ----//
        selPiece = GUILayout.SelectionGrid(selPiece, pcList, 2,
            myBox,
            GUILayout.Width(100), GUILayout.Height(350),
            GUILayout.MinHeight(0), GUILayout.MinWidth(0));


        EditorGUILayout.EndVertical();
        //---- End Right Side ----//

        EditorGUILayout.EndHorizontal();
        outString = GUILayout.TextField(outString, GUILayout.Height(100));
    }
}
