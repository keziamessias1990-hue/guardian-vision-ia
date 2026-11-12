import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CreateParentDto, ParentRecord } from '../guardian.types';
import { mockParents } from '../mock-data';

@Controller('parents')
export class ParentsController {
  @Get()
  list(): ParentRecord[] {
    return mockParents;
  }

  @Get(':id')
  detail(@Param('id') id: string): ParentRecord | undefined {
    return mockParents.find((parent) => parent.id === id);
  }

  @Post()
  create(@Body() body: CreateParentDto): ParentRecord {
    const parent: ParentRecord = {
      id: `parent-${Date.now()}`,
      name: body.name,
      email: body.email,
      createdAt: new Date().toISOString(),
    };

    mockParents.push(parent);
    return parent;
  }
}
