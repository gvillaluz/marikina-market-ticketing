// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordinance_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrdinanceHiveModelAdapter extends TypeAdapter<OrdinanceHiveModel> {
  @override
  final int typeId = 0;

  @override
  OrdinanceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, Object?>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrdinanceHiveModel(
      ordinanceId: fields[0] as int,
      ordinanceNo: fields[1] as String,
      ordinanceCode: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String,
      category: fields[5] as String,
      createdAt: fields[6] as DateTime,
      severity: fields[7] as String,
      series: fields[8] == null ? '' : fields[8] as String,
      marketCode: fields[9] == null ? '' : fields[9] as String,
      updatedAt: fields[10] as DateTime?,
      isActive: fields[11] == null ? true : fields[11] as bool,
      penaltyTierCount: fields[12] == null ? 0 : fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OrdinanceHiveModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.ordinanceId)
      ..writeByte(1)
      ..write(obj.ordinanceNo)
      ..writeByte(2)
      ..write(obj.ordinanceCode)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.severity)
      ..writeByte(8)
      ..write(obj.series)
      ..writeByte(9)
      ..write(obj.marketCode)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.penaltyTierCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdinanceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
