import 'dart:math';

/// A formal processing recipe transforming raw farm crops into refined goods.
class ProcessingRecipe {
  const ProcessingRecipe({
    required this.id,
    required this.name,
    required this.inputCropId,
    required this.inputAmount,
    required this.outputItemId,
    required this.outputAmount,
    required this.processingDurationSeconds,
    required this.outputUnitValueCredits,
    required this.shelfLifeExtensionFactor,
  });

  final String id;
  final String name;
  final String inputCropId;
  final int inputAmount;
  final String outputItemId;
  final int outputAmount;
  final double processingDurationSeconds;
  final int outputUnitValueCredits;

  /// Factor that slows down perishability degradation (e.g. 0.3 means 70% slower spoiling).
  final double shelfLifeExtensionFactor;
}

/// Catalog of standard processing recipes approved in game design brief.
abstract final class ProcessingRecipeCatalog {
  /// Wheat -> Wheat Flour
  static const ProcessingRecipe wheatFlour = ProcessingRecipe(
    id: 'rcp_wheat_flour',
    name: 'Buğday Unu',
    inputCropId: 'CR01',
    inputAmount: 5,
    outputItemId: 'wheat_flour',
    outputAmount: 5,
    processingDurationSeconds: 15.0,
    outputUnitValueCredits: 85,
    shelfLifeExtensionFactor: 0.30,
  );

  /// Maize -> Cornmeal / Corn Flour
  static const ProcessingRecipe cornmeal = ProcessingRecipe(
    id: 'rcp_cornmeal',
    name: 'Mısır Unu',
    inputCropId: 'CR02',
    inputAmount: 5,
    outputItemId: 'cornmeal',
    outputAmount: 5,
    processingDurationSeconds: 15.0,
    outputUnitValueCredits: 95,
    shelfLifeExtensionFactor: 0.30,
  );

  /// Sunflower -> Cold-Pressed Sunflower Oil
  static const ProcessingRecipe sunflowerOil = ProcessingRecipe(
    id: 'rcp_sunflower_oil',
    name: 'Ayçiçek Yağı',
    inputCropId: 'CR03',
    inputAmount: 6,
    outputItemId: 'sunflower_oil',
    outputAmount: 4,
    processingDurationSeconds: 25.0,
    outputUnitValueCredits: 175,
    shelfLifeExtensionFactor: 0.15,
  );

  /// Potato -> Potato Starch
  static const ProcessingRecipe potatoStarch = ProcessingRecipe(
    id: 'rcp_potato_starch',
    name: 'Patates Nişastası',
    inputCropId: 'CR04',
    inputAmount: 8,
    outputItemId: 'potato_starch',
    outputAmount: 4,
    processingDurationSeconds: 30.0,
    outputUnitValueCredits: 190,
    shelfLifeExtensionFactor: 0.20,
  );

  static const ProcessingRecipe chickpeaFlour = ProcessingRecipe(
    id: 'rcp_chickpea_flour',
    name: 'Nohut unu',
    inputCropId: 'CR05',
    inputAmount: 5,
    outputItemId: 'chickpea_flour',
    outputAmount: 4,
    processingDurationSeconds: 24.0,
    outputUnitValueCredits: 155,
    shelfLifeExtensionFactor: 0.25,
  );

  static const ProcessingRecipe packedPotatoes = ProcessingRecipe(
    id: 'rcp_packed_potatoes',
    name: 'Paketlenmiş patates',
    inputCropId: 'CR04',
    inputAmount: 5,
    outputItemId: 'packed_potatoes',
    outputAmount: 5,
    processingDurationSeconds: 20.0,
    outputUnitValueCredits: 105,
    shelfLifeExtensionFactor: 0.25,
  );

  static const ProcessingRecipe goatMilk = ProcessingRecipe(
    id: 'rcp_goat_milk',
    name: 'Keçi sütü',
    inputCropId: 'CR01',
    inputAmount: 5,
    outputItemId: 'goat_milk',
    outputAmount: 2,
    processingDurationSeconds: 60.0,
    outputUnitValueCredits: 75,
    shelfLifeExtensionFactor: 0.10,
  );

  static const ProcessingRecipe honey = ProcessingRecipe(
    id: 'rcp_honey',
    name: 'Bal',
    inputCropId: 'CR03',
    inputAmount: 3,
    outputItemId: 'honey',
    outputAmount: 1,
    processingDurationSeconds: 90.0,
    outputUnitValueCredits: 125,
    shelfLifeExtensionFactor: 0.35,
  );

  static const ProcessingRecipe wool = ProcessingRecipe(
    id: 'rcp_wool',
    name: 'Yün',
    inputCropId: 'CR01',
    inputAmount: 6,
    outputItemId: 'wool',
    outputAmount: 2,
    processingDurationSeconds: 90.0,
    outputUnitValueCredits: 115,
    shelfLifeExtensionFactor: 0.40,
  );

  static const ProcessingRecipe cowMilk = ProcessingRecipe(
    id: 'rcp_cow_milk',
    name: 'Süt',
    inputCropId: 'CR01',
    inputAmount: 8,
    outputItemId: 'cow_milk',
    outputAmount: 4,
    processingDurationSeconds: 60.0,
    outputUnitValueCredits: 82,
    shelfLifeExtensionFactor: 0.10,
  );

  static const List<ProcessingRecipe> all = [
    wheatFlour,
    cornmeal,
    sunflowerOil,
    potatoStarch,
    chickpeaFlour,
    packedPotatoes,
    goatMilk,
    honey,
    wool,
    cowMilk,
  ];

  static ProcessingRecipe? byId(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static ProcessingRecipe? forInputCrop(String cropId) {
    try {
      return all.firstWhere((r) => r.inputCropId == cropId);
    } catch (_) {
      return null;
    }
  }
}

/// Operational state of a processing facility.
enum FacilityStatus {
  idle,
  processing,
  starvedInput, // Waiting for raw ingredients
  blockedOutput, // Output warehouse/buffer is full
}

/// Item inventory lot inside a facility input or output buffer.
class InventoryLot {
  InventoryLot({
    required this.itemId,
    required this.amount,
    required this.ageMinutes,
    this.quality = 1.0,
  });

  final String itemId;
  int amount;
  double ageMinutes;
  double quality;

  InventoryLot copyWith({
    String? itemId,
    int? amount,
    double? ageMinutes,
    double? quality,
  }) => InventoryLot(
    itemId: itemId ?? this.itemId,
    amount: amount ?? this.amount,
    ageMinutes: ageMinutes ?? this.ageMinutes,
    quality: quality ?? this.quality,
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'amount': amount,
    'ageMinutes': ageMinutes,
    'quality': quality,
  };

  factory InventoryLot.fromJson(Map<String, dynamic> json) => InventoryLot(
    itemId: json['itemId'] as String,
    amount: json['amount'] as int,
    ageMinutes: (json['ageMinutes'] as num).toDouble(),
    quality: (json['quality'] as num?)?.toDouble() ?? 1.0,
  );
}

/// Single processing facility (Flour Mill, Oil Press, Starch Refinery).
class ProcessingFacility {
  ProcessingFacility({
    required this.id,
    required this.name,
    required this.positionX,
    required this.positionY,
    required this.allowedRecipeIds,
    this.inputBufferCapacity = 50,
    this.outputBufferCapacity = 50,
    this.status = FacilityStatus.idle,
    this.activeRecipeId,
    this.batchProgressSeconds = 0.0,
    this.totalInputProcessed = 0,
    this.totalOutputProduced = 0,
    List<InventoryLot>? inputBuffer,
    List<InventoryLot>? outputBuffer,
    this.isUnlocked = false,
  }) : inputBuffer = inputBuffer ?? [],
       outputBuffer = outputBuffer ?? [];

  final String id;
  final String name;
  final double positionX;
  final double positionY;
  final List<String> allowedRecipeIds;
  int inputBufferCapacity;
  int outputBufferCapacity;
  FacilityStatus status;
  String? activeRecipeId;
  double batchProgressSeconds;
  int totalInputProcessed;
  int totalOutputProduced;
  final List<InventoryLot> inputBuffer;
  final List<InventoryLot> outputBuffer;
  bool isUnlocked;

  int get totalInputAmount =>
      inputBuffer.fold(0, (sum, lot) => sum + lot.amount);
  int get totalOutputAmount =>
      outputBuffer.fold(0, (sum, lot) => sum + lot.amount);

  int get remainingInputCapacity =>
      max(0, inputBufferCapacity - totalInputAmount);
  int get remainingOutputCapacity =>
      max(0, outputBufferCapacity - totalOutputAmount);

  /// Deposits raw crop into the input buffer.
  bool depositInput(
    String cropId,
    int amount, {
    double ageMinutes = 0.0,
    double quality = 1.0,
  }) {
    if (amount <= 0 || remainingInputCapacity < amount) return false;
    inputBuffer.add(
      InventoryLot(
        itemId: cropId,
        amount: amount,
        ageMinutes: ageMinutes,
        quality: quality,
      ),
    );
    return true;
  }

  /// Extracts finished goods from the output buffer (FIFO).
  int extractOutput(int maxAmount) {
    if (maxAmount <= 0 || outputBuffer.isEmpty) return 0;
    int remaining = maxAmount;
    int extracted = 0;

    while (outputBuffer.isNotEmpty && remaining > 0) {
      final lot = outputBuffer.first;
      final take = min(lot.amount, remaining);
      lot.amount -= take;
      extracted += take;
      remaining -= take;

      if (lot.amount <= 0) {
        outputBuffer.removeAt(0);
      }
    }
    return extracted;
  }

  /// Deterministic simulation step: verifies inputs, processes batch, and deposits outputs.
  void update(double dtSeconds, {Set<String>? eligibleRecipeIds}) {
    if (!isUnlocked || dtSeconds <= 0) return;

    final recipesForThisStep = eligibleRecipeIds ?? allowedRecipeIds.toSet();

    // Age output products gently
    for (final lot in outputBuffer) {
      lot.ageMinutes += (dtSeconds / 60.0);
      lot.quality = max(0.40, lot.quality - 0.0005 * (dtSeconds / 60.0));
    }

    // If currently processing a batch
    if (status == FacilityStatus.processing && activeRecipeId != null) {
      if (!recipesForThisStep.contains(activeRecipeId)) return;
      final recipe = ProcessingRecipeCatalog.byId(activeRecipeId!);
      if (recipe == null) {
        status = FacilityStatus.idle;
        return;
      }

      batchProgressSeconds += dtSeconds;
      if (batchProgressSeconds >= recipe.processingDurationSeconds) {
        // Batch completed!
        if (remainingOutputCapacity >= recipe.outputAmount) {
          outputBuffer.add(
            InventoryLot(
              itemId: recipe.outputItemId,
              amount: recipe.outputAmount,
              ageMinutes: 0.0,
              quality: 1.0,
            ),
          );
          totalInputProcessed += recipe.inputAmount;
          totalOutputProduced += recipe.outputAmount;
          batchProgressSeconds = 0.0;
          activeRecipeId = null;
          status = FacilityStatus.idle;
        } else {
          // Output is blocked
          status = FacilityStatus.blockedOutput;
          return;
        }
      }
      return;
    }

    // Try starting a new batch from allowed recipes
    for (final rId in recipesForThisStep) {
      final recipe = ProcessingRecipeCatalog.byId(rId);
      if (recipe == null) continue;

      // Check input availability
      final availableInput = inputBuffer
          .where((l) => l.itemId == recipe.inputCropId)
          .fold(0, (sum, l) => sum + l.amount);

      if (availableInput >= recipe.inputAmount) {
        // Check output capacity
        if (remainingOutputCapacity < recipe.outputAmount) {
          status = FacilityStatus.blockedOutput;
          return;
        }

        // Consume inputs according to FIFO rule
        int needed = recipe.inputAmount;
        while (inputBuffer.isNotEmpty && needed > 0) {
          final lot = inputBuffer.firstWhere(
            (l) => l.itemId == recipe.inputCropId,
          );
          final take = min(lot.amount, needed);
          lot.amount -= take;
          needed -= take;
          if (lot.amount <= 0) {
            inputBuffer.remove(lot);
          }
        }

        activeRecipeId = recipe.id;
        batchProgressSeconds = 0.0;
        status = FacilityStatus.processing;
        return;
      }
    }

    // If no recipe could be started
    status = FacilityStatus.starvedInput;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'positionX': positionX,
    'positionY': positionY,
    'allowedRecipeIds': allowedRecipeIds,
    'inputBufferCapacity': inputBufferCapacity,
    'outputBufferCapacity': outputBufferCapacity,
    'status': status.name,
    if (activeRecipeId != null) 'activeRecipeId': activeRecipeId,
    'batchProgressSeconds': batchProgressSeconds,
    'totalInputProcessed': totalInputProcessed,
    'totalOutputProduced': totalOutputProduced,
    'inputBuffer': inputBuffer.map((l) => l.toJson()).toList(),
    'outputBuffer': outputBuffer.map((l) => l.toJson()).toList(),
    'isUnlocked': isUnlocked,
  };

  factory ProcessingFacility.fromJson(Map<String, dynamic> json) =>
      ProcessingFacility(
        id: json['id'] as String,
        name: json['name'] as String,
        positionX: (json['positionX'] as num).toDouble(),
        positionY: (json['positionY'] as num).toDouble(),
        allowedRecipeIds: (json['allowedRecipeIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        inputBufferCapacity: json['inputBufferCapacity'] as int? ?? 50,
        outputBufferCapacity: json['outputBufferCapacity'] as int? ?? 50,
        status: FacilityStatus.values.byName(
          json['status'] as String? ?? FacilityStatus.idle.name,
        ),
        activeRecipeId: json['activeRecipeId'] as String?,
        batchProgressSeconds:
            (json['batchProgressSeconds'] as num?)?.toDouble() ?? 0.0,
        totalInputProcessed: json['totalInputProcessed'] as int? ?? 0,
        totalOutputProduced: json['totalOutputProduced'] as int? ?? 0,
        inputBuffer: (json['inputBuffer'] as List<dynamic>?)
            ?.map((l) => InventoryLot.fromJson(l as Map<String, dynamic>))
            .toList(),
        outputBuffer: (json['outputBuffer'] as List<dynamic>?)
            ?.map((l) => InventoryLot.fromJson(l as Map<String, dynamic>))
            .toList(),
        isUnlocked: json['isUnlocked'] as bool? ?? false,
      );
}

/// Factory manager organizing all processing plants on the farm.
class ProcessingPlantManager {
  ProcessingPlantManager({List<ProcessingFacility>? facilities})
    : facilities = facilities ?? <ProcessingFacility>[];

  final List<ProcessingFacility> facilities;

  /// A new farm starts without processing buildings. Facilities are added only
  /// when an operational, researched building is synchronized by its session.
  static List<ProcessingFacility> get defaultFacilities =>
      <ProcessingFacility>[];

  void update(double dtSeconds) {
    for (final facility in facilities) {
      facility.update(dtSeconds);
    }
  }

  Map<String, dynamic> toJson() => {
    'facilities': facilities.map((f) => f.toJson()).toList(),
  };

  factory ProcessingPlantManager.fromJson(Map<String, dynamic> json) =>
      ProcessingPlantManager(
        facilities: (json['facilities'] as List<dynamic>?)?.map((f) {
          final facility = ProcessingFacility.fromJson(
            f as Map<String, dynamic>,
          );
          // Authorization is rebuilt from the farm's buildings and
          // research by OpeningSession after loading the save.
          facility.isUnlocked = false;
          return facility;
        }).toList(),
      );
}
