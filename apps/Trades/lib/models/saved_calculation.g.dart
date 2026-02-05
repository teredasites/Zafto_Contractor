// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_calculation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalculatorTypeAdapter extends TypeAdapter<CalculatorType> {
  @override
  final int typeId = 10;

  @override
  CalculatorType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CalculatorType.voltageDrop;
      case 1:
        return CalculatorType.wireSizing;
      case 2:
        return CalculatorType.conduitFill;
      case 3:
        return CalculatorType.boxFill;
      case 4:
        return CalculatorType.motorFla;
      case 5:
        return CalculatorType.ampacity;
      case 6:
        return CalculatorType.conduitBending;
      case 7:
        return CalculatorType.dwellingLoad;
      case 8:
        return CalculatorType.transformer;
      case 9:
        return CalculatorType.grounding;
      case 10:
        return CalculatorType.powerConverter;
      case 11:
        return CalculatorType.pullBox;
      case 12:
        return CalculatorType.motorCircuit;
      case 13:
        return CalculatorType.faultCurrent;
      case 14:
        return CalculatorType.commercialLoad;
      case 15:
        return CalculatorType.tapRule;
      case 16:
        return CalculatorType.lumen;
      case 17:
        return CalculatorType.unitConverter;
      case 18:
        return CalculatorType.raceway;
      case 19:
        return CalculatorType.parallelConductor;
      case 20:
        return CalculatorType.powerFactor;
      case 21:
        return CalculatorType.disconnect;
      case 22:
        return CalculatorType.serviceEntrance;
      case 23:
        return CalculatorType.evCharger;
      case 24:
        return CalculatorType.solarPv;
      case 25:
        return CalculatorType.electricRange;
      case 26:
        return CalculatorType.dryerCircuit;
      case 27:
        return CalculatorType.waterHeater;
      case 28:
        return CalculatorType.generatorSizing;
      case 29:
        return CalculatorType.continuousLoad;
      case 30:
        return CalculatorType.motorInrush;
      case 31:
        return CalculatorType.mwbc;
      case 32:
        return CalculatorType.cableTray;
      case 33:
        return CalculatorType.lightingSqft;
      case 34:
        return CalculatorType.ohmsLaw;
      default:
        return CalculatorType.voltageDrop;
    }
  }

  @override
  void write(BinaryWriter writer, CalculatorType obj) {
    switch (obj) {
      case CalculatorType.voltageDrop:
        writer.writeByte(0);
        break;
      case CalculatorType.wireSizing:
        writer.writeByte(1);
        break;
      case CalculatorType.conduitFill:
        writer.writeByte(2);
        break;
      case CalculatorType.boxFill:
        writer.writeByte(3);
        break;
      case CalculatorType.motorFla:
        writer.writeByte(4);
        break;
      case CalculatorType.ampacity:
        writer.writeByte(5);
        break;
      case CalculatorType.conduitBending:
        writer.writeByte(6);
        break;
      case CalculatorType.dwellingLoad:
        writer.writeByte(7);
        break;
      case CalculatorType.transformer:
        writer.writeByte(8);
        break;
      case CalculatorType.grounding:
        writer.writeByte(9);
        break;
      case CalculatorType.powerConverter:
        writer.writeByte(10);
        break;
      case CalculatorType.pullBox:
        writer.writeByte(11);
        break;
      case CalculatorType.motorCircuit:
        writer.writeByte(12);
        break;
      case CalculatorType.faultCurrent:
        writer.writeByte(13);
        break;
      case CalculatorType.commercialLoad:
        writer.writeByte(14);
        break;
      case CalculatorType.tapRule:
        writer.writeByte(15);
        break;
      case CalculatorType.lumen:
        writer.writeByte(16);
        break;
      case CalculatorType.unitConverter:
        writer.writeByte(17);
        break;
      case CalculatorType.raceway:
        writer.writeByte(18);
        break;
      case CalculatorType.parallelConductor:
        writer.writeByte(19);
        break;
      case CalculatorType.powerFactor:
        writer.writeByte(20);
        break;
      case CalculatorType.disconnect:
        writer.writeByte(21);
        break;
      case CalculatorType.serviceEntrance:
        writer.writeByte(22);
        break;
      case CalculatorType.evCharger:
        writer.writeByte(23);
        break;
      case CalculatorType.solarPv:
        writer.writeByte(24);
        break;
      case CalculatorType.electricRange:
        writer.writeByte(25);
        break;
      case CalculatorType.dryerCircuit:
        writer.writeByte(26);
        break;
      case CalculatorType.waterHeater:
        writer.writeByte(27);
        break;
      case CalculatorType.generatorSizing:
        writer.writeByte(28);
        break;
      case CalculatorType.continuousLoad:
        writer.writeByte(29);
        break;
      case CalculatorType.motorInrush:
        writer.writeByte(30);
        break;
      case CalculatorType.mwbc:
        writer.writeByte(31);
        break;
      case CalculatorType.cableTray:
        writer.writeByte(32);
        break;
      case CalculatorType.lightingSqft:
        writer.writeByte(33);
        break;
      case CalculatorType.ohmsLaw:
        writer.writeByte(34);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedCalculationAdapter extends TypeAdapter<SavedCalculation> {
  @override
  final int typeId = 11;

  @override
  SavedCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedCalculation(
      id: fields[0] as String,
      calculatorType: fields[1] as CalculatorType,
      name: fields[2] as String?,
      notes: fields[3] as String?,
      inputs: (fields[4] as Map).cast<String, dynamic>(),
      outputs: (fields[5] as Map).cast<String, dynamic>(),
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
      jobId: fields[8] as String?,
      jobAddress: fields[9] as String?,
      isFavorite: fields[10] as bool? ?? false,
      tags: (fields[11] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, SavedCalculation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.calculatorType)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.inputs)
      ..writeByte(5)
      ..write(obj.outputs)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.jobId)
      ..writeByte(9)
      ..write(obj.jobAddress)
      ..writeByte(10)
      ..write(obj.isFavorite)
      ..writeByte(11)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCalculationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
