unit MapUtils;

interface
	uses SwinGame, Terrain;

	type
		//
		//	Represents the current camera position in tile-based sizing, i.e.
		//	32px = a single tile.
		//
		TileView = record
			x, y, right, bottom: LongInt;
		end;

	// Loads all game resources
	procedure LoadResources();

	//
	//	Creates a new TileView record from the view currently within the
	//	games camera bounds.
	//
	function CreateTileView(constref map: MapData): TileView;

	//
	//	Updates the camera position relative to the players
	//	position. Moves the offset according to how close the player
	//	is to the edge of the map, ensuring the player never sees outside
	//	the map bounds.
	//
	procedure UpdateCamera(constref map: MapData);

	//
	//	Draws a smaller sized map to the screen for the player to view
	//
	procedure DrawMapCartography(var map: MapData);
implementation

	procedure LoadResources();
	begin
		LoadBitmapNamed('water', 'water.png');
		LoadBitmapNamed('dark water', 'dark_water.png');
		LoadBitmapNamed('dirt', 'dirt.png');
		LoadBitmapNamed('grass', 'grass.png');
		LoadBitmapNamed('dark grass', 'dark_grass.png');
		LoadBitmapNamed('darkest grass', 'super_dark_grass.png');
		LoadBitmapNamed('sand', 'sand.png');
		LoadBitmapNamed('mountain', 'mountain.png');
		LoadBitmapNamed('snowy grass', 'snowy_grass.png');
		LoadBitmapNamed('tree', 'tree.png');
		LoadBitmapNamed('pine tree', 'pine_tree.png');
		LoadBitmapNamed('palm tree', 'palm_tree.png');
		LoadBitmapNamed('snowy tree', 'snowy_tree.png');
		LoadBitmapNamed('player', 'player.png');
		LoadBitmapNamed('hidden', 'hidden.png');
	end;

	function CreateTileView(constref map: MapData): TileView;
	var
		x, y: Integer;
		width, height: LongInt;
		newView: TileView;
	begin
		// Translate camera view to tile-based values
		newView.x := Round(CameraPos.x / map.tilesize) - 1;
		newView.y := Round(CameraPos.y / map.tilesize) - 1;
		newView.right := Round( (CameraPos.x / map.tilesize) + (ScreenWidth() / map.tilesize) );
		newView.bottom := Round( (CameraPos.y / map.tilesize) + (ScreenHeight() / map.tilesize) );

		result := newView;
	end;

	procedure UpdateCamera(constref map: MapData);
	var
		offsetX, offsetY, rightEdgeDistance, bottomEdgeDistance, halfWidth, halfHeight: Single;
		mapSizeToPixel, halfSprite: Integer;
	begin
		mapSizeToPixel := ( High(map.tiles) - 1 ) * map.tilesize;
		rightEdgeDistance := mapSizeToPixel - SpriteX(map.player);
		bottomEdgeDistance := mapSizeToPixel - SpriteY(map.player);
		halfSprite := Round(SpriteWidth(map.player) / 2);
		halfWidth := ScreenWidth() / 2;
		halfHeight := ScreenHeight() / 2;

		offsetX := 0;
		offsetY := 0;

		// Left edge of the map
		if CameraX() < (halfWidth + halfSprite * 2) then
		begin
			offsetX := ( ScreenWidth() - SpriteX(map.player) + halfSprite ) / 2;
		end;
		//Right edge of map
		if ( SpriteX(map.player) + halfWidth + halfSprite ) > mapSizeToPixel then
		begin
			offsetX := -( halfWidth - rightEdgeDistance + halfSprite );
		end;
		// Top edge of map
		if CameraY() < (halfHeight + halfSprite * 2) then
		begin
			offsetY := ( ScreenHeight() - SpriteY(map.player) + halfSprite ) / 2;
		end;
		// Bottom edge of map
		if ( SpriteY(map.player) + halfHeight + halfSprite ) > mapSizeToPixel then
		begin
			offsetY := -( halfHeight - bottomEdgeDistance + halfSprite);
		end;

		CenterCameraOn(map.player, offsetX, offsetY);
	end;

	procedure DrawMapCartography(var map: MapData);
	var
		clr: Color;
		i, j, x, y, step: Integer;
	begin
		// Increment the flash counter for player pos
		map.playerIndicator += 1;

		// Give map blue background
		ClearScreen(RGBColor(42, 76, 211));
		// used to give the rendered map a size that fits in the screen no matter how large it is
		step := Round((map.size - 1) / 512);
		// Don't increase step for small maps
		if map.size = 257 then
		begin
			step := 1;
		end;

		x := 0;
		for i := 0 to High(map.tiles) do
		begin
			// Don't try to render any pixels outside the map bounds or it don't work
			if x > map.size - 1 then
			begin
				break;
			end;

			y := 0;
			for j := 0 to High(map.tiles) do
			begin
				// Don't try to render any pixels outside the map bounds or it don't work
				if y > map.size - 1 then
				begin
					break;
				end;

				// Get color based on terrain flag
				case map.tiles[x, y].flag of
					Water: clr := RGBColor(42, 76, 211); // Blue
					Sand: clr := RGBColor(241, 249, 101); // Sandy yellow
					Grass: clr := RGBColor(139, 230, 128); // Light green
					Dirt: clr := RGBColor(148, 92, 53); // Brown
					MediumGrass: clr := RGBColor(57, 167, 63); // darker green
					HighGrass: clr := RGBColor(23, 125, 29); // Dark green
					SnowyGrass: clr := ColorWhite;
					Mountain: clr := RGBColor(119, 119, 119); // Grey
				end;
				// Render trees
				if map.tiles[x, y].feature = Tree then
				begin
					clr := RGBColor(113, 149, 48); // Olive
				end;
				// Render a black border around the map
				if (x = 0) or (x = High(map.tiles)) or (y = 0) or (y = High(map.tiles)) then
				begin
					clr := ColorBlack;
				end;
				// Draw tile as pixel. Use 130 & 50 to center the map
				DrawPixel(clr, CameraX() + i + 130, CameraY() + j + 50);
				y += step;
			end;
			x += step;
		end;
		if map.playerIndicator > 2 then
		begin
			// Draw the players position on the map
			FillRectangle(
					ColorRed,
					CameraX() + ( (SpriteX(map.player) / 32) / step) + 130,
					CameraY() + ( (SpriteY(map.player) / 32) / step) + 50,
					4,
					4
				);
			if map.playerIndicator > 4 then
			begin
				map.playerIndicator := 0;
			end;
		end;
		RefreshScreen(60);
	end;

end.
