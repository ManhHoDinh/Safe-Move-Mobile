import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:traffic_solution_dsc/core/constraints/status.dart';
import 'package:traffic_solution_dsc/core/models/camera/camera.dart';
import 'package:traffic_solution_dsc/core/models/placeNear/placeNear.dart';
import 'dart:convert' as convert;

part 'home_state.dart';
part 'home_cubit.freezed.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState.initial(data: HomeStateData()));
  void setCameraPosition(LatLng latLng) {
    try {
      emit(HomeState.loading(
          data: state.data!.copyWith(status: StatusType.loading)));
      CameraPosition _camera = CameraPosition(
        target: latLng,
        zoom: 13,
      );
      print("reset");
      emit(HomeState.getLocationSelectedCamera(
          data: state.data!.copyWith(locationSelectedCamera: _camera)));
    } catch (e) {
      emit(HomeState.error(data: state.data!.copyWith(error: e.toString())));
    }
  }

  Future<LatLng> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR" + error.toString());
    });
    Position currentPosition = await Geolocator.getCurrentPosition();

    return LatLng(currentPosition.latitude, currentPosition.longitude);
  }

  void setCurrentLocation() async {
    try {
      emit(HomeState.loading(
          data: state.data!.copyWith(status: StatusType.loading)));
      CameraPosition _camera = CameraPosition(
        target: await getUserCurrentLocation(),
        zoom: 13,
      );

      emit(HomeState.getLocationSelectedCamera(
          data: state.data!.copyWith(locationSelectedCamera: _camera)));
    } catch (e) {
      emit(HomeState.error(data: state.data!.copyWith(error: e.toString())));
    }
  }

  Future<List<Camera>> fetchCameras() async {
    final response = await http.get(
      Uri.parse(
          'https://api.notis.vn/v4/cameras/bybbox?lat1=11.160767&lng1=106.554166&lat2=9.45&lng2=128.99999'),
      headers: {
        'accept': 'application/json',
        'device-id': 'bf738a0a3e6eddc2',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Camera.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cameras');
    }
  }

  Future<HomeStateData> getPlaceNear(LatLng latLng) async {
    try {
      emit(HomeState.loading(
          data: state.data!.copyWith(status: StatusType.loading)));
      final headers = {
        'X-RapidAPI-Host': 'trueway-places.p.rapidapi.com',
        'X-RapidAPI-Key': 'b1a1bfce34msh0287fa31caec574p100443jsnd9d5e7fc04c2',
      };

      final params = {
        'location': '${latLng.latitude},${latLng.longitude}',
        //'type': 'cafe',
        //'radius': '180',
        'language': 'vi',
      };

      final url =
          Uri.parse('https://trueway-places.p.rapidapi.com/FindPlacesNearby')
              .replace(queryParameters: params);

      final res = await http.get(url, headers: headers);
      final status = res.statusCode;
      if (status != 200) throw Exception('http.get error: statusCode= $status');
      print(res.body);
      PlaceNear place = PlaceNear.fromJson(convert.jsonDecode(res.body));

      emit(HomeState.getLocationSelected(
          data: state.data!
              .copyWith(status: StatusType.loaded, locationSelected: place)));
      return state.data!;
    } catch (e) {
      return HomeStateData();
    }
  }
}
