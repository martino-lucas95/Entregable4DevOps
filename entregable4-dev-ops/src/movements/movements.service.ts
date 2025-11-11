import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMovementDto } from './dto/create-movement.dto';
import { MovementType } from '../common/enums/movement-type.enum';

@Injectable()
export class MovementsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateMovementDto) {
    // 1) Validar que el producto exista
    const product = await this.prisma.product.findUnique({
      where: { id: dto.productId },
    });

    if (!product) {
      throw new NotFoundException(`Product ${dto.productId} not found`);
    }

    // 2) Si es salida, validar que no deje el stock negativo
    if (dto.type === MovementType.OUT) {
      const currentStock = await this.getStock(product.id);

      if (dto.quantity > currentStock) {
        throw new BadRequestException(
          `Not enough stock. Current: ${currentStock}, requested: ${dto.quantity}`,
        );
      }
    }

    // 3) Crear movimiento
    return this.prisma.movement.create({
      data: {
        productId: dto.productId,
        type: dto.type,
        quantity: dto.quantity,
      },
    });
  }

  async findAll() {
    return this.prisma.movement.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: number) {
    const movement = await this.prisma.movement.findUnique({ where: { id } });

    if (!movement) {
      throw new NotFoundException(`Movement ${id} not found`);
    }

    return movement;
  }

  // Helper usado para validación
  async getStock(productId: number): Promise<number> {
    const result = await this.prisma.movement.groupBy({
      by: ['type'],
      where: { productId },
      _sum: { quantity: true },
    });

    const ins =
      result.find((r) => r.type === MovementType.IN)?._sum.quantity ?? 0;
    const outs =
      result.find((r) => r.type === MovementType.OUT)?._sum.quantity ?? 0;

    return ins - outs;
  }
}
