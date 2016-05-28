program GameMain;
uses SwinGame, sgTypes, Terrain, MapUtils;

//	Initializes the 2D map grid with the given size and sets the default 
//	values for each tile
procedure SetGridLength(var tiles: TileGrid; size: Integer);
var
	column: Integer;
	x, y: Integer;
begin

	for column := 0 to size do
	begin
		SetLength(tiles, column, size);
	end;

	for x := 0 to High(tiles) do
	begin
		for y := 0 to High(tiles) do
		begin
			// Setup default values
			tiles[x, y].elevation := 0;
			tiles[x, y].collidable := false;
			tiles[x, y].feature := NoFeature;
			tiles[x, y].hasBmp := false;
		end;
	end;
end;

//
//	Initializes a new tile grid and then generates a new map using DiamondSquare().
//	The new map can be random or based off a given seed
//
function CreateMap(size: Integer; random: Boolean; seed: Integer = 0): MapData;
var
	i, j: Integer;
	spawnFound: Boolean;
begin
	result.tilesize := 32;
	result.size := size;
	result.player := CreateSprite('player', BitmapNamed('player'));

	// Setup seed
	if random then
	begin
		Randomize
	end
	else
	begin
		RandSeed := seed;
	end;

	// Initialize Tile Grid
	SetGridLength(result.tiles, size);
	// Generate Heightmap
	DiamondSquare(result, 100, 20);

	GenerateTerrain(result);

	//
	//	Search for the first sand tile without a feature on it,
	//	thus spawning the player on a beach
	//
	spawnFound := false;
	for i := 0 to High(result.tiles) do
	begin
		if spawnFound then
			break;

		for j := 0 to High(result.tiles) do
		begin
			if spawnFound then
				break;

			if (i > 1) and (result.tiles[i, j].flag = Sand) and (result.tiles[i, j].feature = NoFeature) then
			begin
				SpriteSetX(result.player, i * 32);
				SpriteSetY(result.player, j * 32);
				result.playerX := i;
				result.playerY := j;
				spawnFound := true;
			end;
		end;
	end;

	// Recursively call self with higher smoothness value if spawn not found
	if not spawnFound then
	begin
		CreateMap(size, random, seed);
	end;
end;

// Prints all of the elevation data in a tilemap to the console.
// Don't use for maps larger than 16 x 16 or it will be bigger than the console window
procedure PrintMapToConsole(constref map: MapData);
var
	x, y: Integer;
begin
	for x := 0 to High(map.tiles) do
  begin
  	for y := 0 to High(map.tiles) do
  	begin
  		Write(map.tiles[x, y].elevation, ' ');
  	end;
  	WriteLn();
  end;
end;

function IsInMap(constref map: MapData; x, y: Integer): Boolean;
begin
	result := false;

	// Check map bounds. As every map is (2^n)+1 in size, the bounds
	// stop at High()-1 which will be a number equal to 2^n.
	if (x > 0) and (x < High(map.tiles) - 1) and (y > 0) and (y < High(map.tiles) - 1) then
	begin
		result := true;
	end;
end;

procedure DrawMap(constref map: MapData);
var
	x, y: Integer;
	newView: TileView;
begin
	newView := CreateTileView(map);

	for x := newView.x to newView.right do
  	begin
	  	for y := newView.y to newView.bottom do
	  	begin
	  		if IsInMap(map, x, y) then
	  		begin
	  			if map.tiles[x, y].hasBmp then
		  		begin
		  			DrawBitmap(map.tiles[x, y].bmp, x * map.tilesize, y * map.tilesize);
					DrawBitmap(map.tiles[x, y].featureBmp, x * map.tilesize, y * map.tilesize);
		  		end;
	  		end;
	  	end;
  	end;
end;

procedure HandleInput(var map: MapData);
var
	newX, newY: Integer;
begin

	newX := map.playerX;
	newY := map.playerY;

	if KeyDown(UpKey) then
	begin
		newY -= 1;
	end;
	if KeyDown(RightKey) then
	begin
		newX += 1;
	end;
	if KeyDown(DownKey) then
	begin
		newY += 1;
	end;
	if KeyDown(LeftKey) then
	begin
		newX -= 1;
	end;

	if (newX <= 0) or (newX >= High(map.tiles) - 1) or (map.tiles[newX, newY].flag = Water) then
	begin
		newX := map.playerX;
	end;
	if (newY <= 0) or (newY >= High(map.tiles) - 1) or (map.tiles[newX, newY].flag = Water) then
	begin
		newY := map.playerY;
	end;

	map.playerY := newY;
	map.playerX := newX;

	SpriteSetY(map.player, map.playerY * map.tilesize);
	SpriteSetX(map.player, map.playerX * map.tilesize);

end;

procedure Main();
var
	map: MapData;
	moveDelay: Integer;
begin

	LoadResources();
  	OpenGraphicsWindow('Procedural Map Generation', 800, 600);
  
	map := CreateMap(257, true);
	//PrintMapToConsole(map);
	moveDelay := 0;
	repeat
		ProcessEvents();

		ClearScreen(ColorWhite);
		
		moveDelay += 1;
		if moveDelay > 3 then
		begin
			HandleInput(map);
			moveDelay := 0;
		end;

		UpdateCamera(map);
		DrawMap(map);
		DrawSprite(map.player);

		if KeyTyped(EscapeKey) then
		begin
			ProcessEvents();
			repeat
				ProcessEvents();
				DrawMapCartography(map);
			until KeyTyped(EscapeKey);
		end;

		RefreshScreen(60);
	until WindowCloseRequested();
end;

begin
  Main();
end.
