import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { MovementsService } from './movements.service';
import { CreateMovementDto } from './dto/create-movement.dto';

@ApiTags('movements')
@Controller('movements')
export class MovementsController {
  constructor(private readonly movementsService: MovementsService) {}

  @Post()
  @ApiOperation({ summary: 'Crear un nuevo movimiento de stock' })
  @ApiResponse({ status: 201, description: 'Movimiento creado exitosamente' })
  @ApiResponse({ status: 400, description: 'Datos inválidos o stock insuficiente' })
  @ApiResponse({ status: 404, description: 'Producto no encontrado' })
  create(@Body() dto: CreateMovementDto) {
    return this.movementsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Obtener todos los movimientos' })
  @ApiResponse({ status: 200, description: 'Lista de movimientos' })
  findAll() {
    return this.movementsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener un movimiento por ID' })
  @ApiParam({ name: 'id', description: 'ID del movimiento' })
  @ApiResponse({ status: 200, description: 'Movimiento encontrado' })
  @ApiResponse({ status: 404, description: 'Movimiento no encontrado' })
  findOne(@Param('id') id: string) {
    return this.movementsService.findOne(Number(id));
  }
}
