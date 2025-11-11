import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateProductDto) {
    return this.prisma.product.create({
      data: {
        name: dto.name,
        cost: dto.cost,
        price: dto.price,
        barcode: dto.barcode ?? null,
      },
    });
  }

  async findAll() {
    return this.prisma.product.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: number) {
    const product = await this.prisma.product.findUnique({ where: { id } });

    if (!product) {
      throw new NotFoundException(`Product with id ${id} not found`);
    }

    return product;
  }

  async update(id: number, dto: UpdateProductDto) {
    // Verificar existencia primero
    await this.findOne(id);

    return this.prisma.product.update({
      where: { id },
      data: {
        ...dto,
        updatedAt: new Date(),
      },
    });
  }

  async remove(id: number) {
    // Verificar existencia primero
    await this.findOne(id);

    await this.prisma.product.delete({ where: { id } });

    return { message: `Product ${id} deleted` };
  }
}
