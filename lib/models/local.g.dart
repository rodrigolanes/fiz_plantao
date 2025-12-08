// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalAdapter extends TypeAdapter<Local> {
  @override
  final int typeId = 0;

  @override
  Local read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Local(
      id: fields[0] as String,
      apelido: fields[1] as String,
      nome: fields[2] as String,
      criadoEm: fields[3] as DateTime,
      atualizadoEm: fields[4] as DateTime,
      ativo: fields[5] as bool,
      userId: fields[6] as String,
      deletadoEm: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Local obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.apelido)
      ..writeByte(2)
      ..write(obj.nome)
      ..writeByte(3)
      ..write(obj.criadoEm)
      ..writeByte(4)
      ..write(obj.atualizadoEm)
      ..writeByte(5)
      ..write(obj.ativo)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.deletadoEm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
