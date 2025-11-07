// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plantao.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlantaoAdapter extends TypeAdapter<Plantao> {
  @override
  final int typeId = 1;

  @override
  Plantao read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Plantao(
      id: fields[0] as String,
      local: fields[1] as Local,
      dataHora: fields[2] as DateTime,
      duracao: fields[3] as Duracao,
      valor: fields[4] as double,
      previsaoPagamento: fields[5] as DateTime,
      criadoEm: fields[6] as DateTime,
      atualizadoEm: fields[7] as DateTime,
      ativo: fields[8] as bool,
      userId: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Plantao obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.local)
      ..writeByte(2)
      ..write(obj.dataHora)
      ..writeByte(3)
      ..write(obj.duracao)
      ..writeByte(4)
      ..write(obj.valor)
      ..writeByte(5)
      ..write(obj.previsaoPagamento)
      ..writeByte(6)
      ..write(obj.criadoEm)
      ..writeByte(7)
      ..write(obj.atualizadoEm)
      ..writeByte(8)
      ..write(obj.ativo)
      ..writeByte(9)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantaoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DuracaoAdapter extends TypeAdapter<Duracao> {
  @override
  final int typeId = 2;

  @override
  Duracao read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Duracao.dozeHoras;
      case 1:
        return Duracao.vinteQuatroHoras;
      default:
        return Duracao.dozeHoras;
    }
  }

  @override
  void write(BinaryWriter writer, Duracao obj) {
    switch (obj) {
      case Duracao.dozeHoras:
        writer.writeByte(0);
        break;
      case Duracao.vinteQuatroHoras:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuracaoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
