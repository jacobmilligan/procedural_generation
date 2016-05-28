unit Terrain;

interface
	uses SwinGame;

	type

		//
		//	Valid tile types for building maps with.
		//	Used as a terrain flag for different logic.
		//
		TileType = (Water, Sand, Dirt, Grass, MediumGrass, HighGrass, SnowyGrass, Mountain);

		//
		//	Represents a feature on top of a tile that can have a bitmap,
		//	collision, and be interactive
		//
		FeatureType = (NoFeature, Tree);

		//
		//	Represents a tile on the map - has a terrain flag,
		//	elevation and bitmap
		//
		Tile = record
			// terrain type
			flag: TileType;

			// type of feature if any
			feature: FeatureType;

			// uses collision detection
			collidable: Boolean;

			//
			//	Represents the tiles elevation - zero represents sea
			//	level.
			//
			elevation: Integer;

			// tiles base bitmap
			bmp: Bitmap;

			hasBmp: Boolean;

			// bitmap for whatever feature is on top of the tiles
			featureBmp: Bitmap;
		end;

		//
		//	Array used to hold a tilemap
		//
		TileGrid = array of array of Tile;

		//
		//	Main representation of the current map. Holds a tile grid, alongside
		//	data related to size, smoothness, seed values.
		//
		MapData = record
			tiles: TileGrid;
			player: Sprite;
			playerX, playerY: Integer;
			size, seed, tilesize, playerIndicator: Integer;
		end;

	//
	//	Fills a MapData's TileGrid with generated heightmap data
	//	using the Diamond-Square fractal generation algorithm
	//	This heightmap data gets used later on to generate terrain realistically
	//
	procedure DiamondSquare(var map: MapData; maxHeight, smoothness: Integer);

	procedure GenerateTerrain(var map: MapData);


implementation

	procedure DiamondSquare(var map: MapData; maxHeight, smoothness: Integer);
	var
		x, y: Integer;
		midpointVal: Double;
		nextStep, cornerCount: Integer;
	begin
		x := 0;
		y := 0;
		midpointVal := 0;
		nextStep := Round(Length(map.tiles) / 2 ); // Center of the tile grid

		// Seed upper-left corner extremely low elevation to force it to
		// start with water
		map.tiles[x, y].elevation := -1500;

		// Initialize four corners of map with the same value as above
		while x < Length(map.tiles) do
		begin
			while y < Length(map.tiles) do
			begin
				map.tiles[x, y].elevation := map.tiles[0, 0].elevation;
				y += 2 * nextStep;
			end;

			x += 2 * nextStep;
			y := 0;
		end;

		x := 0;
		y := 0;

		//
		// Generate the rest of the heightmap now that the first square
		// has been generated. Keep iterating until the next step in the
		// grid is less than zero, i.e. the whole grid has been generated.
		//
		while nextStep > 0 do
		begin
			midpointVal := 0;

			//
			// Diamond step.
			// Check surrounding points in a diamond around a given midpoint, i.e.:
			//  	  x
			//  	x o x
			//   	  x
			// The circle represents the midpoint. Checks if they're within the bounds
			// of the map
			//
			x := nextStep;
			while x < Length(map.tiles) do
			begin

				y := nextStep;
				while y < Length(map.tiles) do
				begin

					//
					// Sum the surrounding points equidistant from the current
					// midpoint, checking in a diamond shape, then calculating their
					// average and adding a random amount less than the max elevation
					//
					midpointVal := map.tiles[x - nextStep, y - nextStep].elevation
								 + map.tiles[x - nextStep, y + nextStep].elevation
								 + map.tiles[x + nextStep, y - nextStep].elevation
								 + map.tiles[x + nextStep, y + nextStep].elevation;

					// Set midpoint to the average + Random value and multiply by smoothing factor
					map.tiles[x, y].elevation := Round( (midpointVal / 4) + (Random(maxHeight) * smoothness) );
					y += 2 * nextStep;
				end;

				x += 2 * nextStep;
				y := 0;
			end;

			//
			// Square step - from the midpoint of the previous square
			// sum the values of the corners, calculate their average
			// and add a random value less than the max elevation
			// to the total result to give the midpoint square an elevation.
			//
			x := 0;
			while x < Length(map.tiles) do
			begin

				y := nextStep * ( 1 - Round(x / nextStep) mod 2);
				while y < Length(map.tiles) do
				begin
					midpointVal := 0;
					cornerCount := 0;

					//
					// Sum surrounding points equidistant from the midpoint
					// in a square shape only if they're within the bounds
					// of the map.
					//
					if ( y - nextStep >= 0 ) then
					begin
						midpointVal += map.tiles[x, y - nextStep].elevation;
						cornerCount += 1;
					end;
					if ( x + nextStep < Length(map.tiles) ) then
					begin
						midpointVal += map.tiles[x + nextStep, y].elevation;
						cornerCount += 1;
					end;
					if ( y + nextStep < Length(map.tiles) ) then
					begin
						midpointVal += map.tiles[x, y + nextStep].elevation;
						cornerCount += 1;
					end;
					if ( x - nextStep >= 0 ) then
					begin
						midpointVal += map.tiles[x - nextStep, y].elevation;
						cornerCount += 1;
					end;

					//
					// If at least one corner is within the map bounds, calculate average plus
					// a random amount less than the map size.
					//
					if cornerCount > 0 then
					begin
						// Set midpoint to the average of corner amt + Random value and multiply by smoothing factor
						map.tiles[x, y].elevation := Round( (midpointVal / cornerCount) + Random(maxHeight) * smoothness );
					end;

					y += 2 * nextStep;
				end;

				x += nextStep;
			end;

			nextStep := Round(nextStep / 2); // Make the next space smaller

			//
			//	Increase smoothness for every iteration, allowing
			//	less difference in height the more iterations that are completed
			//
			smoothness := Round(smoothness / 2);
		end;
	end;

	procedure SetTile(var newTile: Tile; flag: TileType; bmp: String; collidable: Boolean);
	begin
		newTile.flag := flag;
		newTile.bmp := BitmapNamed(bmp);
		newTile.collidable := collidable;
		newTile.hasBmp := true;
	end;

	// Generates the terrain type for each tile based off its elevation value
	procedure GenerateTerrain(var map: MapData);
	var
		x, y: Integer;
	begin
		// Iterate all tiles and change their bitmap and data depending on their
		// pre-generated altitude
		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin

				// Setup the tiles
				case map.tiles[x, y].elevation of
					0..199: SetTile(map.tiles[x, y], Water, 'water', true);
					200..299: SetTile(map.tiles[x, y], Sand, 'sand', false);
					300..399: SetTile(map.tiles[x, y], Grass, 'grass', false);
					400..599: SetTile(map.tiles[x, y], MediumGrass, 'dark grass', false);
					600..799: SetTile(map.tiles[x, y], HighGrass, 'darkest grass', false);
					800..999: if Random(10) > 6 then
											SetTile(map.tiles[x, y], SnowyGrass, 'snowy grass', false)
										else
											SetTile(map.tiles[x, y], HighGrass, 'darkest grass', false);
					1000..1499: SetTile(map.tiles[x, y], SnowyGrass, 'snowy grass', false);
					else
						if map.tiles[x, y].elevation  < 0 then
							SetTile(map.tiles[x, y], Water, 'dark water', true)
						else
							SetTile(map.tiles[x, y], Mountain, 'mountain', true)
				end;

			end;
		end;
	end;

end.
