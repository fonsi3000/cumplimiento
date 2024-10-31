<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DebidaDiligenciaResource\Pages;
use App\Models\DebidaDiligencia;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use pxlrbt\FilamentExcel\Actions\Tables\ExportAction;
use pxlrbt\FilamentExcel\Actions\Tables\ExportBulkAction;
use pxlrbt\FilamentExcel\Exports\ExcelExport;

class DebidaDiligenciaResource extends Resource
{
    protected static ?string $model = DebidaDiligencia::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-check';
    
    protected static ?string $modelLabel = 'Debida Diligencia';
    
    protected static ?string $pluralModelLabel = 'Debidas Diligencias';
    
    protected static ?string $navigationGroup = 'Gestión de Riesgos';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make()
                ->schema([
                    Forms\Components\TextInput::make('debida_diligencia')
                        ->label('Debida diligencia')
                        ->maxLength(255),

                    Forms\Components\Grid::make(2)
                        ->schema([
                            Forms\Components\DatePicker::make('fecha_ingreso_correo')
                                ->label('Fecha de ingreso del correo')
                                ->required()
                                ->default(now()),

                            Forms\Components\TimePicker::make('hora_ingreso_correo')
                                ->label('Hora de ingreso al correo')
                                ->required()
                                ->default(now())
                                ->seconds(false),

                            Forms\Components\Select::make('empresa_solicitante')
                                ->label('Empresa solicitante')
                                ->options([
                                    'ESPUMAS MEDELLÍN S.A' => 'ESPUMAS MEDELLÍN S.A',
                                    'ESPUMADOS DEL LITORAL S.A' => 'ESPUMADOS DEL LITORAL S.A',
                                    'STN CARGA & LOGÍSTICA S.A.S' => 'STN CARGA & LOGÍSTICA S.A.S'
                                ])
                                ->required()
                                ->searchable(),

                            Forms\Components\Select::make('responsable')
                                ->options([
                                    'Daniela Arrendo' => 'Daniela Arredondo',
                                    'Sofia Velez' => 'Sofia Velez',
                                    'Catalina Hernández' => 'Catalina Hernández'
                                ])
                                ->required()
                                ->searchable(),

                            Forms\Components\DatePicker::make('fecha_respuesta')
                                ->label('Fecha de respuesta'),

                            Forms\Components\Select::make('estado')
                                ->options([
                                    'Terminado' => 'Terminado',
                                    'Pendiente' => 'Pendiente'
                                ])
                                ->required()
                                ->default('Pendiente'),

                            Forms\Components\Select::make('nivel_riesgo')
                                ->label('Nivel de riesgo')
                                ->options([
                                    'Alto' => 'Alto',
                                    'Medio' => 'Medio',
                                    'Bajo' => 'Bajo'
                                ])
                                ->required(),

                            Forms\Components\Toggle::make('coincidencia_listas')
                                ->label('Coincidencia en lista')
                                ->inline(false),

                            Forms\Components\Toggle::make('coincidencia_noticia')
                                ->label('Coincidencia en noticia')
                                ->inline(false),

                            Forms\Components\Toggle::make('correo_enviado_oc')
                                ->label('Correo enviado al OC')
                                ->inline(false),

                            Forms\Components\Select::make('tipo_vinculacion')
                                ->label('Tipo de vinculación')
                                ->options([
                                    'Nuevo' => 'Nuevo',
                                    'Actualizado' => 'Actualizado'
                                ])
                                ->required(),

                            Forms\Components\Select::make('contraparte')
                                ->options([
                                    'Cliente' => 'Cliente',
                                    'Proveedor' => 'Proveedor',
                                    'Colaborador' => 'Colaborador'
                                ])
                                ->required(),

                            Forms\Components\Select::make('tipo_persona')
                                ->label('Tipo de persona')
                                ->options([
                                    'Natural' => 'Natural',
                                    'Jurídica' => 'Jurídica'
                                ])
                                ->required(),

                            Forms\Components\Select::make('documentacion')
                                ->label('Documentación')
                                ->options([
                                    'Completa' => 'Completa',
                                    'Incompleta' => 'Incompleta',
                                    'Pendiente' => 'Pendiente'
                                ])
                                ->default('Pendiente')
                                ->required(),

                            Forms\Components\Select::make('area_solicitante')
                                ->label('Área solicitante')
                                ->options([
                                    'Cartera' => 'Cartera',
                                    'Compras' => 'Compras',
                                    'Gestion Humana' => 'Gestion Humana'
                                ])
                                ->required(),
                        ]),

                    Forms\Components\Textarea::make('observaciones_documentacion')
                        ->label('Observaciones de documentación')
                        ->columnSpanFull(),

                    Forms\Components\Grid::make(2)
                        ->schema([
                            Forms\Components\DatePicker::make('fecha_recepcion_documentos')
                                ->label('Fecha Recepción de documentos faltantes o subsanados'),

                            Forms\Components\TimePicker::make('hora_recepcion')
                                ->label('Hora Recepción')
                                ->seconds(false),
                        ]),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('fecha_ingreso_correo')
                    ->label('Fecha Ingreso')
                    ->date()
                    ->sortable(),
                
                Tables\Columns\TextColumn::make('empresa_solicitante')
                    ->label('Empresa')
                    ->searchable()
                    ->sortable(),
                
                Tables\Columns\TextColumn::make('responsable')
                    ->searchable(),
                
                Tables\Columns\BadgeColumn::make('estado')
                    ->colors([
                        'danger' => 'Pendiente',
                        'warning' => 'En Proceso',
                        'success' => 'Terminada',
                    ]),
                
                Tables\Columns\BadgeColumn::make('nivel_riesgo')
                    ->colors([
                        'success' => 'Bajo',
                        'warning' => 'Medio',
                        'danger' => 'Alto',
                    ]),
                
                Tables\Columns\TextColumn::make('area_solicitante')
                    ->label('Área'),
                
                Tables\Columns\IconColumn::make('coincidencia_listas')
                    ->label('Listas')
                    ->boolean(),
                
                Tables\Columns\BadgeColumn::make('documentacion')
                    ->colors([
                        'danger' => 'Incompleta',
                        'warning' => 'En Proceso',
                        'success' => 'Completa',
                    ]),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->options([
                        'Pendiente' => 'Pendiente',
                        'En Proceso' => 'En Proceso',
                        'Terminada' => 'Terminada',
                    ]),
                
                Tables\Filters\SelectFilter::make('nivel_riesgo')
                    ->options([
                        'Bajo' => 'Bajo',
                        'Medio' => 'Medio',
                        'Alto' => 'Alto',
                    ]),
                
                Tables\Filters\SelectFilter::make('area_solicitante')
                    ->label('Área')
                    ->options([
                        'CARTERA' => 'Cartera',
                        'COMPRAS' => 'Compras',
                        'GESTION HUMANA' => 'Gestión Humana',
                        'COMERCIAL' => 'Comercial',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    ExportBulkAction::make() // Agregamos aquí la acción de exportación
                        ->exports([
                            ExcelExport::make('table')
                                ->fromTable()
                                ->withFilename('Debidas Diligencias - ' . date('Y-m-d')),
                            ExcelExport::make('form')
                                ->fromForm()
                                ->withFilename('Debidas Diligencias - ' . date('Y-m-d')),
                        ]),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDebidaDiligencias::route('/'),
            'create' => Pages\CreateDebidaDiligencia::route('/create'),
            'edit' => Pages\EditDebidaDiligencia::route('/{record}/edit'),
        ];
    }
}